/// Photomator Channel Mixer (`m`) → Nitro ChannelMixer, 1:1 (`constant` → `bias`).
/// Rows Photomator did not store are identity. See `docs/mapping.md` §2.4.
enum ChannelMixerMapper: BlockMapper {
    static let block = PhotomatorBlock.channelMixer

    static func map(_ adjustments: PhotomatorAdjustments, context: inout MappingContext) -> [NitroAdjustment.Content] {
        guard let mixer = adjustments.channelMixer else { return [] }
        let identity = NitroChannelMixer()
        func blended(_ row: ChannelMixerRow?, _ neutral: NitroChannelMixer.Row) -> NitroChannelMixer.Row {
            guard let row else { return neutral }
            return NitroChannelMixer.Row(
                red: context.blend(neutral.red, row.red),
                green: context.blend(neutral.green, row.green),
                blue: context.blend(neutral.blue, row.blue),
                bias: context.blend(neutral.bias, row.constant))
        }
        var nitro = identity
        nitro.red = blended(mixer.red, identity.red)
        nitro.green = blended(mixer.green, identity.green)
        nitro.blue = blended(mixer.blue, identity.blue)
        return nitro == identity ? [] : [.channelMixer(nitro)]
    }
}
