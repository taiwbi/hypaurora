declare const SRC: string

declare module "inline:*" {
  const content: string
  export default content
}

declare module "*.scss" {
  const content: string
  export default content
}

declare module "*.blp" {
  const content: string
  export default content
}

declare module "*.css" {
  const content: string
  export default content
}

// Astal GObject Introspection modules
declare module "gi://AstalHyprland" {
  const Hyprland: any
  export default Hyprland
}

declare module "gi://AstalMpris" {
  const Mpris: any
  export default Mpris
}

declare module "gi://AstalBattery" {
  const Battery: any
  export default Battery
}

declare module "gi://AstalNetwork" {
  const Network: any
  export default Network
}

declare module "gi://AstalWp" {
  const Wp: any
  export default Wp
}
