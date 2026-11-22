/// Photomator Channel Mixer (`m`) → Nitro ChannelMixer, 1:1 (`constant` → `bias`).
/// Rows Photomator did not store are identity. See `docs/mapping.md` §2.4.
enum ChannelMixerMapper {
    static func map(_ mixer: PhotomatorChannelMixer, intensity: Double) -> NitroAdjustment.Content? {
        var nitro = NitroChannelMixer()
        let identity = nitro
        func row(_ row: ChannelMixerRow?, default neutral: NitroChannelMixer.Row) -> NitroChannelMixer.Row {
            guard let row else { return neutral }
            return NitroChannelMixer.Row(
                red: blend(neutral.red, row.red, intensity),
                green: blend(neutral.green, row.green, intensity),
                blue: blend(neutral.blue, row.blue, intensity),
                bias: blend(neutral.bias, row.constant, intensity))
        }
        nitro.red = row(mixer.red, default: identity.red)
        nitro.green = row(mixer.green, default: identity.green)
        nitro.blue = row(mixer.blue, default: identity.blue)
        return nitro == identity ? nil : .channelMixer(nitro)
    }
}
