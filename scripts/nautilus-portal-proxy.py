#!/usr/bin/python3

"""Expose Nautilus' FileChooser backend without a GTK4 startup deadlock.

GTK4 Nautilus currently blocks while the portal frontend is still acquiring
its own D-Bus name.  The frontend also asks a backend for Properties.GetAll
while it starts, while Nautilus' generated skeleton does not answer that call
reliably when it has no properties.  This small, non-GTK D-Bus bridge answers
the probe immediately and forwards real chooser requests to Nautilus after
the portal frontend is ready.
"""

import gi

gi.require_version("Gio", "2.0")
gi.require_version("GLib", "2.0")

from gi.repository import Gio, GLib


BUS_NAME = "org.hypaurora.NautilusPortal"
OBJECT_PATH = "/org/freedesktop/portal/desktop"
INTERFACE = "org.freedesktop.impl.portal.FileChooser"
NAUTILUS_NAME = "org.gnome.Nautilus"


INTROSPECTION_XML = f"""
<node>
  <interface name="{INTERFACE}">
    <method name="OpenFile">
      <arg type="o" name="handle" direction="in"/>
      <arg type="s" name="app_id" direction="in"/>
      <arg type="s" name="parent_window" direction="in"/>
      <arg type="s" name="title" direction="in"/>
      <arg type="a{{sv}}" name="options" direction="in"/>
      <arg type="u" name="response" direction="out"/>
      <arg type="a{{sv}}" name="results" direction="out"/>
    </method>
    <method name="SaveFile">
      <arg type="o" name="handle" direction="in"/>
      <arg type="s" name="app_id" direction="in"/>
      <arg type="s" name="parent_window" direction="in"/>
      <arg type="s" name="title" direction="in"/>
      <arg type="a{{sv}}" name="options" direction="in"/>
      <arg type="u" name="response" direction="out"/>
      <arg type="a{{sv}}" name="results" direction="out"/>
    </method>
    <method name="SaveFiles">
      <arg type="o" name="handle" direction="in"/>
      <arg type="s" name="app_id" direction="in"/>
      <arg type="s" name="parent_window" direction="in"/>
      <arg type="s" name="title" direction="in"/>
      <arg type="a{{sv}}" name="options" direction="in"/>
      <arg type="u" name="response" direction="out"/>
      <arg type="a{{sv}}" name="results" direction="out"/>
    </method>
    <property name="version" type="u" access="read"/>
  </interface>
</node>
"""


def forward_call(connection, method, parameters, invocation):
    try:
        proxy = Gio.DBusProxy.new_sync(
            connection,
            Gio.DBusProxyFlags.DO_NOT_LOAD_PROPERTIES
            | Gio.DBusProxyFlags.DO_NOT_CONNECT_SIGNALS,
            None,
            NAUTILUS_NAME,
            OBJECT_PATH,
            INTERFACE,
            None,
        )
    except GLib.Error as error:
        invocation.return_gerror(error)
        return

    def on_done(proxy_object, result, _user_data):
        try:
            invocation.return_value(proxy_object.call_finish(result))
        except GLib.Error as error:
            invocation.return_gerror(error)

    proxy.call(method, parameters, Gio.DBusCallFlags.NONE, -1, None, on_done, None)


def method_call(connection, sender, object_path, interface_name, method, parameters, invocation):
    if interface_name != INTERFACE:
        invocation.return_dbus_error(
            "org.freedesktop.DBus.Error.UnknownMethod",
            f"Unknown interface {interface_name}",
        )
        return

    forward_call(connection, method, parameters, invocation)


def get_property(_connection, _sender, _object_path, interface_name, property_name):
    if interface_name == INTERFACE and property_name == "version":
        return GLib.Variant("u", 4)
    return None


def set_property(_connection, _sender, _object_path, _interface_name, _property_name, _value):
    return False


def on_bus_acquired(connection, _name):
    node_info = Gio.DBusNodeInfo.new_for_xml(INTROSPECTION_XML)
    interface_info = node_info.interfaces[0]
    connection.register_object_with_closures2(
        OBJECT_PATH,
        interface_info,
        method_call,
        get_property,
        set_property,
    )


def main():
    loop = GLib.MainLoop()
    owner_id = Gio.bus_own_name(
        Gio.BusType.SESSION,
        BUS_NAME,
        Gio.BusNameOwnerFlags.NONE,
        on_bus_acquired,
        None,
        None,
    )
    try:
        loop.run()
    finally:
        Gio.bus_unown_name(owner_id)


if __name__ == "__main__":
    main()
