import UniformTypeIdentifiers

extension UTType {
    /// Photomator / Pixelmator Pro adjustments package (`.adjustments`). Apps must also import
    /// this type in their Info.plist (`UTImportedTypeDeclarations`, see App/Info.plist) so
    /// pickers and drops recognise it.
    public static let photomatorAdjustments = UTType(importedAs: "com.pixelmatorteam.adjustments",
                                                      conformingTo: .package)
}
