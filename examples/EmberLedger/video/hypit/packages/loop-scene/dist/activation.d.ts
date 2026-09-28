import type { ComponentPackage, ModuleManifest, StructuredSurfaceHandler } from "@hypit/hypit/author-kit";
export declare const manifest: ModuleManifest;
export declare const decodeSurface: StructuredSurfaceHandler;
export declare const hypitPackage: {
    format: "hypit.node-package@1";
    modules: {
        manifest: ModuleManifest;
    }[];
    components: ComponentPackage[];
    hostFacets: {
        readonly abi: string;
        readonly offers?: readonly string[];
        readonly implementation: unknown;
    }[];
};
export default hypitPackage;
