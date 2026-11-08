#!/usr/bin/env python3
"""Orbital connection manager. NetworkManager owns profiles and credentials."""
import os
import subprocess
import threading

import gi

gi.require_version('Gtk', '4.0')
gi.require_version('Adw', '1')
gi.require_version('NM', '1.0')
from gi.repository import Adw, Gio, GLib, Gtk, NM

AP_FLAGS = getattr(NM, '80211ApFlags')

CSS = b'''
window { background: #080f1e; color: #d5eafb; }
headerbar { background: #0d1729; box-shadow: none; }
.content { padding: 24px; }
.hero { background: linear-gradient(120deg, #113247, #24213f);
        border: 1px solid alpha(#60e7ff, .22); border-radius: 20px; padding: 22px; }
.hero-icon { color: #60e7ff; margin-right: 16px; }
.hero-title { font-size: 26px; font-weight: 800; }
.eyebrow { color: #72f1e7; font-size: 10px; font-weight: 800; letter-spacing: 2px; }
.subtitle { color: #9db1ca; }
.section-title { font-size: 15px; font-weight: 700; margin-top: 8px; }
list.boxed-list { background: #101d30; border: 1px solid #21334b; border-radius: 15px; }
list.boxed-list row { padding: 5px 8px; }
list.boxed-list row:hover { background: alpha(#60e7ff, .04); }
button { border-radius: 10px; }
button.suggested-action { background: #60e7ff; color: #081725; font-weight: 700; }
.connected { color: #7cfac8; }
.weak { color: #ffd580; }
.error-box { background: #382034; color: #ffd3df; border-radius: 12px; padding: 14px; }
.footnote { color: #8096b3; font-size: 11px; }
'''


def label(text, css=None):
    widget = Gtk.Label(label=text, xalign=0, wrap=True)
    if css:
        widget.add_css_class(css)
    return widget


def button(text, callback, css=None):
    widget = Gtk.Button(label=text, valign=Gtk.Align.CENTER)
    widget.connect('clicked', lambda *_: callback())
    if css:
        widget.add_css_class(css)
    return widget


def ssid_text(value):
    return NM.utils_ssid_to_utf8(value.get_data()) if value else ''


class Connections(Adw.Application):
    def __init__(self):
        super().__init__(application_id='local.orbital.Connections')
        self.client = None
        self.window = None
        self.busy = False

    def do_activate(self):
        if self.window:
            self.window.present()
            return
        self.client = NM.Client.new(None)
        Adw.StyleManager.get_default().set_color_scheme(Adw.ColorScheme.FORCE_DARK)
        self.window = Adw.ApplicationWindow(application=self, title='Connections',
                                           default_width=600, default_height=760)
        provider = Gtk.CssProvider()
        provider.load_from_data(CSS)
        Gtk.StyleContext.add_provider_for_display(self.window.get_display(), provider, 600)
        self.set_accels_for_action('app.close', ['Escape', '<Control>w'])
        close = Gio.SimpleAction.new('close', None)
        close.connect('activate', lambda *_: self.window.close())
        self.add_action(close)
        outer = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        header = Adw.HeaderBar()
        header.set_title_widget(label('Connections'))
        header.pack_start(button('Advanced', self.editor))
        self.refresh_button = button('↻  Refresh', self.scan)
        header.pack_end(self.refresh_button)
        outer.append(header)
        scroll = Gtk.ScrolledWindow(hscrollbar_policy=Gtk.PolicyType.NEVER, vexpand=True)
        body = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=20)
        body.add_css_class('content')
        hero = Gtk.Box(spacing=4)
        hero.add_css_class('hero')
        icon = Gtk.Image.new_from_icon_name('network-wireless-symbolic')
        icon.set_pixel_size(42)
        icon.add_css_class('hero-icon')
        hero.append(icon)
        titles = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=5, hexpand=True)
        titles.append(label('ORBITAL  /  NETWORK', 'eyebrow'))
        titles.append(label('Stay connected', 'hero-title'))
        self.summary = label('Checking your connections…', 'subtitle')
        titles.append(self.summary)
        hero.append(titles)
        body.append(hero)
        body.append(label('Current connections', 'section-title'))
        self.current = Gtk.ListBox(selection_mode=Gtk.SelectionMode.NONE)
        self.current.add_css_class('boxed-list')
        body.append(self.current)
        self.error = label('', 'error-box')
        self.error.set_visible(False)
        body.append(self.error)
        self.status = label('', 'subtitle')
        body.append(self.status)
        radio_list = Gtk.ListBox(selection_mode=Gtk.SelectionMode.NONE)
        radio_list.add_css_class('boxed-list')
        radio_row = Adw.ActionRow(title='Wi-Fi', subtitle='Discover and join nearby networks')
        radio_row.add_prefix(Gtk.Image.new_from_icon_name('network-wireless-symbolic'))
        self.radio = Gtk.Switch(valign=Gtk.Align.CENTER)
        self.radio.set_active(self.client.wireless_get_enabled())
        self.radio.connect('notify::active', self.toggle_wifi)
        radio_row.add_suffix(self.radio)
        radio_list.append(radio_row)
        body.append(radio_list)
        self.search = Gtk.SearchEntry(placeholder_text='Find a network or saved connection')
        self.search.connect('search-changed', lambda *_: self.render())
        body.append(self.search)
        body.append(label('Nearby networks', 'section-title'))
        self.nearby = Gtk.ListBox(selection_mode=Gtk.SelectionMode.NONE)
        self.nearby.add_css_class('boxed-list')
        body.append(self.nearby)
        body.append(label('Saved connections', 'section-title'))
        self.saved = Gtk.ListBox(selection_mode=Gtk.SelectionMode.NONE)
        self.saved.add_css_class('boxed-list')
        body.append(self.saved)
        body.append(label('5 GHz is faster nearby. For a weak signal, try a closer access point or a 2.4 GHz network.\nEsc to close · Advanced for IP, DNS, VPN and hidden networks.', 'footnote'))
        scroll.set_child(body)
        outer.append(scroll)
        self.window.set_content(outer)
        self.client.connect('notify', lambda *_: self.render())
        GLib.timeout_add_seconds(5, self.render)
        self.render()
        self.window.present()
        self.scan()

    def editor(self, uuid=None):
        subprocess.Popen(['nm-connection-editor'] + (['--edit', uuid] if uuid else []))

    def toggle_wifi(self, *_):
        if self.radio.get_active() != self.client.wireless_get_enabled():
            self.run_nm(['radio', 'wifi', 'on' if self.radio.get_active() else 'off'])

    def run_nm(self, args, password=None):
        if self.busy:
            return
        self.busy = True
        self.error.set_visible(False)
        self.status.set_label('Applying connection changes…')
        self.render()

        def worker():
            try:
                result = subprocess.run(['nmcli', '--colors', 'no', '--wait', '35'] + args,
                                        input=(password + '\n') if password is not None else '',
                                        capture_output=True, text=True, timeout=45,
                                        env={**os.environ, 'LC_ALL': 'C'})
                error = result.stderr.strip() if result.returncode else ''
            except (OSError, subprocess.TimeoutExpired) as exc:
                error = str(exc)
            GLib.idle_add(self.finished, error)

        threading.Thread(target=worker, daemon=True).start()

    def finished(self, error):
        self.busy = False
        self.status.set_label('Changes applied.' if not error else 'Connection could not be completed.')
        if error:
            if 'ssid-not-found' in error or 'could not be found' in error:
                error += '\nThe access point may be out of range. Refresh or try a stronger network.'
            self.error.set_label(error)
            self.error.set_visible(True)
        self.render()
        return False

    def scan(self):
        if self.busy:
            return
        devices = [d for d in self.client.get_devices() if isinstance(d, NM.DeviceWifi)]
        if not self.client.wireless_get_enabled() or not devices:
            self.render()
            return
        self.status.set_label('Scanning for nearby networks…')
        self.refresh_button.set_sensitive(False)

        def done(device, result, *_):
            try:
                device.request_scan_finish(result)
                self.status.set_label('Networks refresh automatically every 5 seconds.')
            except GLib.Error as exc:
                self.status.set_label(exc.message)
            self.refresh_button.set_sensitive(True)
            self.render()

        for device in devices:
            device.request_scan_async(None, done, None)

    def password_dialog(self, name, args):
        dialog = Adw.MessageDialog(transient_for=self.window, modal=True,
                                   heading='Join ' + name, body='Enter the Wi-Fi password.')
        entry = Gtk.PasswordEntry(show_peek_icon=True, hexpand=True)
        entry.connect('activate', lambda *_: dialog.response('connect'))
        dialog.set_extra_child(entry)
        dialog.add_response('cancel', 'Cancel')
        dialog.add_response('connect', 'Connect')
        dialog.set_response_appearance('connect', Adw.ResponseAppearance.SUGGESTED)
        dialog.set_default_response('connect')
        dialog.set_close_response('cancel')
        dialog.connect('response', lambda _, response:
                       self.run_nm(['--ask'] + args, entry.get_text()) if response == 'connect' else None)
        dialog.present()
        entry.grab_focus()

    def join(self, device, ap, profile):
        name = ssid_text(ap.get_ssid())
        if profile:
            self.run_nm(['connection', 'up', 'uuid', profile.get_uuid(), 'ifname', device.get_iface()])
        else:
            args = ['device', 'wifi', 'connect', ap.get_bssid(), 'ifname', device.get_iface()]
            if ap.get_flags() & AP_FLAGS.PRIVACY:
                self.password_dialog(name, args)
            else:
                self.run_nm(args)

    def forget(self, connection):
        dialog = Adw.MessageDialog(transient_for=self.window, modal=True,
                                   heading='Forget ' + connection.get_id() + '?',
                                   body='This removes its saved settings and password. An active connection will disconnect.')
        dialog.add_response('cancel', 'Cancel')
        dialog.add_response('forget', 'Forget')
        dialog.set_response_appearance('forget', Adw.ResponseAppearance.DESTRUCTIVE)
        dialog.set_close_response('cancel')
        dialog.connect('response', lambda _, response:
                       self.run_nm(['connection', 'delete', 'uuid', connection.get_uuid()])
                       if response == 'forget' else None)
        dialog.present()

    def row(self, title, subtitle, icon, target):
        row = Adw.ActionRow(title=GLib.markup_escape_text(title),
                            subtitle=GLib.markup_escape_text(subtitle))
        row.add_prefix(Gtk.Image.new_from_icon_name(icon))
        target.append(row)
        return row

    def render(self):
        if not self.window:
            return True
        for target in (self.current, self.nearby, self.saved):
            while target.get_first_child():
                target.remove(target.get_first_child())
        self.radio.set_sensitive(not self.busy and self.client.wireless_hardware_get_enabled())
        # Block feedback while mirroring changes made by another network app.
        self.radio.handler_block_by_func(self.toggle_wifi)
        self.radio.set_active(self.client.wireless_get_enabled())
        self.radio.handler_unblock_by_func(self.toggle_wifi)
        query = self.search.get_text().casefold()
        active = {a.get_uuid(): a for a in self.client.get_active_connections()}
        primary = self.client.get_primary_connection()
        self.summary.set_label(('Online · ' + primary.get_id()) if primary else 'Choose a network to get online')
        profiles = self.client.get_connections()
        networks = {}
        for device in self.client.get_devices():
            if not isinstance(device, NM.DeviceWifi):
                continue
            for ap in device.get_access_points():
                name = ssid_text(ap.get_ssid())
                band = '6 GHz' if ap.get_frequency() >= 5925 else '5 GHz' if ap.get_frequency() >= 4900 else '2.4 GHz'
                key = (name, band, bool(ap.get_flags() & AP_FLAGS.PRIVACY))
                if not name or query not in name.casefold():
                    continue
                connected = device.get_active_access_point() == ap
                if key not in networks or connected or (not networks[key][2] and ap.get_strength() > networks[key][1].get_strength()):
                    networks[key] = (device, ap, connected)
        for (name, band, secure), (device, ap, connected) in sorted(networks.items(), key=lambda n: (not n[1][2], -n[1][1].get_strength())):
            strength = ap.get_strength()
            matches = [p for p in profiles if p.get_setting_wireless() and
                       ssid_text(p.get_setting_wireless().get_ssid()) == name and device.connection_valid(p) and ap.connection_valid(p)]
            profile = matches[0] if matches else None
            detail = f'{band}  ·  {strength}% signal  ·  ' + ('Secured' if secure else 'Open network')
            if connected:
                detail += '  ·  Connected'
            elif strength < 30:
                detail += '  ·  Weak signal'
            elif profile:
                detail += '  ·  Saved'
            level = 'excellent' if strength >= 75 else 'good' if strength >= 50 else 'ok' if strength >= 30 else 'weak'
            row = self.row(name, detail, f'network-wireless-signal-{level}-symbolic', self.nearby)
            if connected:
                row.add_css_class('connected')
            elif strength < 30:
                row.add_css_class('weak')
            action = button('Disconnect' if connected else 'Connect',
                            (lambda d=device: self.run_nm(['device', 'disconnect', d.get_iface()])) if connected else
                            (lambda d=device, a=ap, p=profile: self.join(d, a, p)),
                            None if connected else 'suggested-action')
            action.set_sensitive(not self.busy)
            row.add_suffix(action)
        if not self.nearby.get_first_child():
            self.row('Wi-Fi is off' if not self.client.wireless_get_enabled() else 'No networks found',
                     'Turn on Wi-Fi above.' if not self.client.wireless_get_enabled() else 'Try Refresh, move closer, or change your search.',
                     'network-wireless-offline-symbolic', self.nearby)
        for profile in sorted(profiles, key=lambda p: (p.get_uuid() != (primary.get_uuid() if primary else None), p.get_id().casefold())):
            kind = profile.get_connection_type()
            if kind not in ('802-11-wireless', '802-3-ethernet', 'vpn', 'wireguard'):
                continue
            uuid = profile.get_uuid()
            connection = profile.get_setting_connection()
            state = active.get(uuid)
            connected = state is not None
            if not connected and query not in profile.get_id().casefold():
                continue
            status = ('Connecting' if state and state.get_state() == NM.ActiveConnectionState.ACTIVATING else 'Active') if connected else 'Saved'
            row = self.row(profile.get_id(), status + '  ·  ' + {'802-11-wireless': 'Wi-Fi', '802-3-ethernet': 'Ethernet', 'vpn': 'VPN', 'wireguard': 'WireGuard'}[kind],
                           'network-wireless-symbolic' if kind == '802-11-wireless' else 'network-wired-symbolic', self.current if connected else self.saved)
            if connected:
                row.add_css_class('connected')
                row.add_suffix(button('Settings', lambda u=uuid: self.editor(u)))
            auto = Gtk.Switch(active=connection.get_autoconnect(), valign=Gtk.Align.CENTER, tooltip_text='Connect automatically')
            auto.connect('notify::active', lambda switch, _, u=uuid: self.run_nm(['connection', 'modify', 'uuid', u, 'connection.autoconnect', 'yes' if switch.get_active() else 'no']))
            row.add_suffix(auto)
            row.add_suffix(button('Disconnect' if connected else 'Connect', lambda u=uuid, on=connected: self.run_nm(['connection', 'down' if on else 'up', 'uuid', u])))
            menu = Gio.Menu()
            for title, suffix, callback in [('Edit settings', 'edit', lambda _, __, u=uuid: self.editor(u)),
                                             ('Enter password…', 'password', lambda _, __, p=profile: self.password_dialog(p.get_id(), ['connection', 'up', 'uuid', p.get_uuid()])),
                                             ('Forget…', 'forget', lambda _, __, p=profile: self.forget(p))]:
                if suffix == 'password' and kind != '802-11-wireless':
                    continue
                action_name = suffix + uuid.replace('-', '')
                old = self.lookup_action(action_name)
                if old:
                    self.remove_action(action_name)
                action = Gio.SimpleAction.new(action_name, None)
                action.connect('activate', callback)
                self.add_action(action)
                menu.append(title, 'app.' + action_name)
            row.add_suffix(Gtk.MenuButton(icon_name='view-more-symbolic', menu_model=menu, valign=Gtk.Align.CENTER))
            row.set_sensitive(not self.busy)
        if not self.current.get_first_child():
            self.row('No current connections', 'Choose a network below to connect.', 'network-offline-symbolic', self.current)
        if not self.saved.get_first_child():
            self.row('No saved connections', 'Joined networks will appear here.', 'network-wired-symbolic', self.saved)
        return True


if __name__ == '__main__':
    Connections().run(None)
