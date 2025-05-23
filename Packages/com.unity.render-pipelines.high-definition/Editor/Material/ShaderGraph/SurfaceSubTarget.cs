using System;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using UnityEngine.Rendering.HighDefinition;
using UnityEditor.ShaderGraph;
using UnityEditor.ShaderGraph.Internal;
using static UnityEngine.Rendering.HighDefinition.HDMaterialProperties;

namespace UnityEditor.Rendering.HighDefinition.ShaderGraph
{
    abstract class SurfaceSubTarget : HDSubTarget, IRequiresData<BuiltinData>
    {
        BuiltinData m_BuiltinData;

        // Interface Properties
        BuiltinData IRequiresData<BuiltinData>.data
        {
            get => m_BuiltinData;
            set => m_BuiltinData = value;
        }

        public BuiltinData builtinData
        {
            get => m_BuiltinData;
            set => m_BuiltinData = value;
        }

        protected override string renderQueue
        {
            get => HDRenderQueue.GetShaderTagValue(HDRenderQueue.ChangeType(systemData.renderQueueType, systemData.sortPriority, systemData.alphaTest, false));
        }

        protected override string disableBatchingTag
        {
            get => builtinData.supportLodCrossFade ? $"{UnityEditor.ShaderGraph.DisableBatching.LODFading}" : $"{UnityEditor.ShaderGraph.DisableBatching.False}";
        }

        protected override string templatePath => $"{HDUtils.GetHDRenderPipelinePath()}Editor/Material/ShaderGraph/Templates/ShaderPass.template";

        protected virtual bool supportForward => false;
        protected virtual bool supportLighting => false;
        protected virtual bool supportDistortion => false;
        protected override bool supportRaytracing => !TargetsVFX() || TargetVFXSupportsRaytracing();

        protected override int ComputeMaterialNeedsUpdateHash()
        {
            // Alpha test is currently the only property in buitin data to trigger the material upgrade script.
            int hash = systemData.alphaTest.GetHashCode();
            return hash;
        }

        static readonly GUID kSourceCodeGuid = new GUID("f4df7e8f9b8c23648ae50cbca0221e47"); // SurfaceSubTarget.cs

        public override void Setup(ref TargetSetupContext context)
        {
            context.AddAssetDependency(kSourceCodeGuid, AssetCollection.Flags.SourceDependency);

            base.Setup(ref context);
        }

        protected override IEnumerable<SubShaderDescriptor> EnumerateSubShaders()
        {
            yield return PostProcessSubShader(GetSubShaderDescriptor());


            if (supportRaytracing || supportPathtracing)
                yield return PostProcessSubShader(GetRaytracingSubShaderDescriptor());

        }

        protected override IEnumerable<KernelDescriptor> EnumerateKernels()
        {
            if (target.supportLineRendering)
            {
                yield return PostProcessKernel(HDShaderKernels.LineRenderingVertexSetup(supportLighting));

                // TODO: We need to do a bit more work to get offscreen shading in compute working.
                // We do it in a shader pass for now in HairPasses.OffscreenShading.
                // yield return PostProcessKernel(HDShaderKernels.GenerateOffscreenShading());
            }
        }

        protected virtual SubShaderDescriptor GetSubShaderDescriptor()
        {
            return new SubShaderDescriptor
            {
                generatesPreview = true,
                passes = GetPasses(),
            };

            PassCollection GetPasses()
            {
                var passes = new PassCollection
                {
                    // Common "surface" passes
                    HDShaderPasses.GenerateShadowCaster(supportLighting, TargetsVFX(), systemData.tessellation),
                    HDShaderPasses.GenerateMETA(supportLighting, TargetsVFX()),
                    HDShaderPasses.GenerateScenePicking(supportLighting, TargetsVFX(), systemData.tessellation),
                    HDShaderPasses.GenerateSceneSelection(supportLighting, TargetsVFX(), systemData.tessellation),
                    HDShaderPasses.GenerateMotionVectors(supportLighting, supportForward, TargetsVFX(), systemData.tessellation),
                    { HDShaderPasses.GenerateBackThenFront(supportLighting, TargetsVFX(), systemData.tessellation), new FieldCondition(HDFields.TransparentBackFace, true)},
                    { HDShaderPasses.GenerateTransparentDepthPostpass(supportLighting, TargetsVFX(), systemData.tessellation), new FieldCondition(HDFields.TransparentDepthPostPass, true)}
                };

                if (supportLighting)
                {
                    // We always generate the TransparentDepthPrepass as it can be use with SSR transparent
                    passes.Add(HDShaderPasses.GenerateTransparentDepthPrepass(true, TargetsVFX(), systemData.tessellation));
                }
                else
                {
                    // We only generate the pass if requested
                    passes.Add(HDShaderPasses.GenerateTransparentDepthPrepass(false, TargetsVFX(), systemData.tessellation), new FieldCondition(HDFields.TransparentDepthPrePass, true));
                }

                if (supportForward)
                {
                    passes.Add(HDShaderPasses.GenerateDepthForwardOnlyPass(supportLighting, TargetsVFX(), systemData.tessellation));
                    passes.Add(HDShaderPasses.GenerateForwardOnlyPass(supportLighting, TargetsVFX(), systemData.tessellation));
                }

                if (supportDistortion)
                    passes.Add(HDShaderPasses.GenerateDistortionPass(supportLighting, TargetsVFX(), systemData.tessellation), new FieldCondition(HDFields.TransparentDistortion, true));

                if (target.supportLineRendering)
                    passes.Add(HDShaderPasses.LineRenderingOffscreenShadingPass(supportLighting));

                passes.Add(HDShaderPasses.GenerateFullScreenDebug(TargetsVFX(), systemData.tessellation));

                return passes;
            }
        }

        protected virtual SubShaderDescriptor GetRaytracingSubShaderDescriptor()
        {
            return new SubShaderDescriptor
            {
                generatesPreview = false,
                passes = GetPasses(),
            };

            PassCollection GetPasses()
            {
                var passes = new PassCollection();

                if (supportRaytracing)
                {
                    // Common "surface" raytracing passes
                    passes.Add(HDShaderPasses.GenerateRaytracingIndirect(supportLighting));
                    passes.Add(HDShaderPasses.GenerateRaytracingVisibility(supportLighting));
                    passes.Add(HDShaderPasses.GenerateRaytracingForward(supportLighting));
                    passes.Add(HDShaderPasses.GenerateRaytracingGBuffer(supportLighting));
                    passes.Add(HDShaderPasses.GenerateRaytracingDebug());
                }
                ;

                if (supportPathtracing)
                    passes.Add(HDShaderPasses.GeneratePathTracing(supportLighting));

                return passes;
            }
        }

        protected override void CollectPassKeywords(ref PassDescriptor pass)
        {
            pass.keywords.Add(CoreKeywordDescriptors.AlphaTest, new FieldCondition(Fields.AlphaTest, true));

            if (pass.IsDepthOrMV())
                pass.keywords.Add(CoreKeywordDescriptors.WriteMsaaDepth);

            if (pass.RequiresTransparentSurfaceTypeKeyword())
                pass.keywords.Add(CoreKeywordDescriptors.SurfaceTypeTransparent);
            pass.keywords.Add(CoreKeywordDescriptors.DoubleSided, new FieldCondition(HDFields.Unlit, false));
            pass.keywords.Add(CoreKeywordDescriptors.DepthOffset, new FieldCondition(HDFields.DepthOffset, true));
            pass.keywords.Add(CoreKeywordDescriptors.ConservativeDepthOffset, new FieldCondition(HDFields.ConservativeDepthOffset, true));

            if (pass.IsMotionVector() || pass.IsForward())
                pass.keywords.Add(CoreKeywordDescriptors.AddPrecomputedVelocity);

            if (pass.RequiresTransparentMVKeyword())
                pass.keywords.Add(CoreKeywordDescriptors.TransparentWritesMotionVector);
            if (pass.RequiresFogOnTransparentKeyword())
                pass.keywords.Add(CoreKeywordDescriptors.FogOnTransparent);

            if (pass.NeedsDebugDisplay())
                pass.keywords.Add(CoreKeywordDescriptors.DebugDisplay);

            if (!pass.IsRelatedToRaytracing())
                pass.keywords.Add(CoreKeywordDescriptors.LodFadeCrossfade, new FieldCondition(Fields.LodCrossFade, true));

            if (pass.lightMode == HDShaderPassNames.s_MotionVectorsStr)
            {
                if (supportForward)
                    pass.defines.Add(CoreKeywordDescriptors.WriteNormalBuffer, 1, new FieldCondition(HDFields.Unlit, false));
                else
                    pass.keywords.Add(CoreKeywordDescriptors.WriteNormalBuffer, new FieldCondition(HDFields.Unlit, false));
            }

            if (pass.IsTessellation())
            {
                pass.keywords.Add(CoreKeywordDescriptors.TessellationMode);
            }
        }

        public override void GetFields(ref TargetFieldContext context)
        {
            base.GetFields(ref context);

            if (systemData.tessellation)
                context.AddField(HDFields.GraphTessellation);

            if (supportDistortion)
                AddDistortionFields(ref context);

            // Mark the shader as unlit so we can remove lighting in FieldConditions
            if (!supportLighting)
                context.AddField(HDFields.Unlit);

            // Common properties between all "surface" master nodes (everything except decal right now)
            context.AddField(HDStructFields.FragInputs.IsFrontFace, systemData.doubleSidedMode != DoubleSidedMode.Disabled && context.pass.referenceName != "SHADERPASS_MOTION_VECTORS");

            // Double Sided
            context.AddField(HDFields.DoubleSided, systemData.doubleSidedMode != DoubleSidedMode.Disabled);

            // We always generate the keyword ALPHATEST_ON. All the variant of AlphaClip (shadow, pre/postpass) are only available if alpha test is on.
            context.AddField(Fields.AlphaTest, systemData.alphaTest
                && (context.pass.validPixelBlocks.Contains(BlockFields.SurfaceDescription.AlphaClipThreshold)
                    || context.pass.validPixelBlocks.Contains(HDBlockFields.SurfaceDescription.AlphaClipThresholdShadow)
                    || context.pass.validPixelBlocks.Contains(HDBlockFields.SurfaceDescription.AlphaClipThresholdDepthPrepass)
                    || context.pass.validPixelBlocks.Contains(HDBlockFields.SurfaceDescription.AlphaClipThresholdDepthPostpass)));

            // All the DoAlphaXXX field drive the generation of which code to use for alpha test in the template
            // Regular alpha test is only done if artist haven't ask to use the specific alpha test shadow one
            bool isShadowPass = (context.pass.lightMode == "ShadowCaster") || (context.pass.lightMode == "VisibilityDXR");
            bool isTransparentDepthPrepass = context.pass.lightMode == "TransparentDepthPrepass";

            // Shadow use the specific alpha test only if user have ask to override it
            context.AddField(HDFields.DoAlphaTestShadow, systemData.alphaTest && builtinData.alphaTestShadow && isShadowPass &&
                context.pass.validPixelBlocks.Contains(HDBlockFields.SurfaceDescription.AlphaClipThresholdShadow));
            // Pre/post pass always use the specific alpha test provided for those pass
            context.AddField(HDFields.DoAlphaTestPrepass, systemData.alphaTest && builtinData.transparentDepthPrepass && isTransparentDepthPrepass &&
                context.pass.validPixelBlocks.Contains(HDBlockFields.SurfaceDescription.AlphaClipThresholdDepthPrepass));

            // Features & Misc
            context.AddField(Fields.LodCrossFade, builtinData.supportLodCrossFade);
            context.AddField(Fields.AlphaToMask, systemData.alphaTest);
            context.AddField(HDFields.TransparentBackFace, builtinData.backThenFrontRendering);
            context.AddField(HDFields.TransparentDepthPrePass, builtinData.transparentDepthPrepass);
            context.AddField(HDFields.TransparentDepthPostPass, builtinData.transparentDepthPostpass);

            context.AddField(HDFields.DepthOffset, builtinData.depthOffset && context.pass.validPixelBlocks.Contains(HDBlockFields.SurfaceDescription.DepthOffset));
            context.AddField(HDFields.ConservativeDepthOffset, builtinData.conservativeDepthOffset && builtinData.depthOffset && context.pass.validPixelBlocks.Contains(HDBlockFields.SurfaceDescription.DepthOffset));

            // Depth offset needs positionRWS and is now a multi_compile
            if (builtinData.depthOffset)
                context.AddField(HDStructFields.FragInputs.positionRWS);

            context.AddField(HDFields.CustomVelocity, systemData.customVelocity);

            context.AddField(HDFields.TessellationFactor, systemData.tessellation);
            context.AddField(HDFields.TessellationDisplacement, systemData.tessellation);
        }

        protected void AddDistortionFields(ref TargetFieldContext context)
        {
            // Distortion
            context.AddField(HDFields.DistortionDepthTest, builtinData.distortionDepthTest);
            context.AddField(HDFields.DistortionAdd, builtinData.distortionMode == DistortionMode.Add);
            context.AddField(HDFields.DistortionMultiply, builtinData.distortionMode == DistortionMode.Multiply);
            context.AddField(HDFields.DistortionReplace, builtinData.distortionMode == DistortionMode.Replace);
            context.AddField(HDFields.TransparentDistortion, systemData.surfaceType != SurfaceType.Opaque && builtinData.distortion);
        }

        public override void GetActiveBlocks(ref TargetActiveBlockContext context)
        {
            if (supportDistortion)
                AddDistortionBlocks(ref context);

            // Common block between all "surface" master nodes
            // Vertex
            context.AddBlock(BlockFields.VertexDescription.Position);
            context.AddBlock(BlockFields.VertexDescription.Normal);
            context.AddBlock(BlockFields.VertexDescription.Tangent);

            // Surface
            context.AddBlock(BlockFields.SurfaceDescription.BaseColor);
            context.AddBlock(BlockFields.SurfaceDescription.Emission);
            context.AddBlock(BlockFields.SurfaceDescription.Alpha);
            context.AddBlock(BlockFields.SurfaceDescription.AlphaClipThreshold, systemData.alphaTest);

            // Alpha Test
            context.AddBlock(HDBlockFields.SurfaceDescription.AlphaClipThresholdDepthPrepass, systemData.alphaTest && builtinData.transparentDepthPrepass);
            context.AddBlock(HDBlockFields.SurfaceDescription.AlphaClipThresholdDepthPostpass, systemData.alphaTest && builtinData.transparentDepthPostpass);
            context.AddBlock(HDBlockFields.SurfaceDescription.AlphaClipThresholdShadow, systemData.alphaTest && builtinData.alphaTestShadow);

            // Misc
            context.AddBlock(HDBlockFields.SurfaceDescription.DepthOffset, builtinData.depthOffset);

            context.AddBlock(HDBlockFields.VertexDescription.CustomVelocity, systemData.customVelocity);

            context.AddBlock(HDBlockFields.VertexDescription.TessellationFactor, systemData.tessellation);
            context.AddBlock(HDBlockFields.VertexDescription.TessellationDisplacement, systemData.tessellation);

            context.AddBlock(HDBlockFields.VertexDescription.Width, target.supportLineRendering);
        }

        protected void AddDistortionBlocks(ref TargetActiveBlockContext context)
        {
            context.AddBlock(HDBlockFields.SurfaceDescription.Distortion, systemData.surfaceType == SurfaceType.Transparent && builtinData.distortion);
            context.AddBlock(HDBlockFields.SurfaceDescription.DistortionBlur, systemData.surfaceType == SurfaceType.Transparent && builtinData.distortion);
        }

        public override void GetPropertiesGUI(ref TargetPropertyGUIContext context, Action onChange, Action<String> registerUndo)
        {
            var gui = new SubTargetPropertiesGUI(context, onChange, registerUndo, systemData, builtinData, null);
            AddInspectorPropertyBlocks(gui);
            context.Add(gui);
        }

        public override void CollectShaderProperties(PropertyCollector collector, GenerationMode generationMode)
        {
            // Trunk currently relies on checking material property "_EmissionColor" to allow emissive GI. If it doesn't find that property, or it is black, GI is forced off.
            // ShaderGraph doesn't use this property, so currently it inserts a dummy color (white). This dummy color may be removed entirely once the following PR has been merged in trunk: Pull request #74105
            // The user will then need to explicitly disable emissive GI if it is not needed.
            // To be able to automatically disable emission based on the ShaderGraph config when emission is black,
            // we will need a more general way to communicate this to the engine (not directly tied to a material property).
            collector.AddShaderProperty(new ColorShaderProperty()
            {
                overrideReferenceName = "_EmissionColor",
                hidden = true,
                overrideHLSLDeclaration = true,
                hlslDeclarationOverride = HLSLDeclaration.UnityPerMaterial,
                value = new Color(1.0f, 1.0f, 1.0f, 1.0f)
            });
            // ShaderGraph only property used to send the RenderQueueType to the material
            collector.AddShaderProperty(new Vector1ShaderProperty
            {
                overrideReferenceName = "_RenderQueueType",
                hidden = true,
                overrideHLSLDeclaration = true,
                hlslDeclarationOverride = HLSLDeclaration.DoNotDeclare,
                value = (int)systemData.renderQueueType,
            });

            //See SG-ADDITIONALVELOCITY-NOTE
            collector.AddShaderProperty(new BooleanShaderProperty
            {
                value = builtinData.addPrecomputedVelocity,
                hidden = true,
                overrideHLSLDeclaration = true,
                hlslDeclarationOverride = HLSLDeclaration.DoNotDeclare,
                overrideReferenceName = kAddPrecomputedVelocity,
            });

            collector.AddShaderProperty(new BooleanShaderProperty
            {
                value = builtinData.depthOffset,
                hidden = true,
                overrideHLSLDeclaration = true,
                hlslDeclarationOverride = HLSLDeclaration.DoNotDeclare,
                overrideReferenceName = kDepthOffsetEnable
            });

            collector.AddShaderProperty(new BooleanShaderProperty
            {
                value = builtinData.conservativeDepthOffset,
                hidden = true,
                overrideHLSLDeclaration = true,
                hlslDeclarationOverride = HLSLDeclaration.DoNotDeclare,
                overrideReferenceName = kConservativeDepthOffsetEnable
            });

            collector.AddShaderProperty(new BooleanShaderProperty
            {
                value = builtinData.transparentWritesMotionVec,
                hidden = true,
                overrideHLSLDeclaration = true,
                hlslDeclarationOverride = HLSLDeclaration.DoNotDeclare,
                overrideReferenceName = kTransparentWritingMotionVec
            });

            // Common properties for all "surface" master nodes
            HDSubShaderUtilities.AddAlphaCutoffShaderProperties(collector, systemData.alphaTest, builtinData.alphaTestShadow);
            HDSubShaderUtilities.AddDoubleSidedProperty(collector, systemData.doubleSidedMode);
            HDSubShaderUtilities.AddPrePostPassProperties(collector, builtinData.transparentDepthPrepass, builtinData.transparentDepthPostpass);

            collector.AddShaderProperty(new BooleanShaderProperty
            {
                value = builtinData.transparentPerPixelSorting,
                hidden = true,
                overrideHLSLDeclaration = true,
                hlslDeclarationOverride = HLSLDeclaration.DoNotDeclare,
                overrideReferenceName = kPerPixelSorting,
            });

            // This adds utility properties for mipmap streaming debugging, only to HLSL since there's no need to expose ShaderLab properties
            // This is, by definition, HLSLDeclaration.UnityPerMaterial
            collector.AddShaderProperty(MipmapStreamingShaderProperties.kDebugTex);

            // Add all shader properties required by the inspector
            HDSubShaderUtilities.AddBlendingStatesShaderProperties(
                collector,
                systemData.surfaceType,
                systemData.blendingMode,
                systemData.sortPriority,
                systemData.transparentZWrite,
                systemData.transparentCullMode,
                systemData.opaqueCullMode,
                systemData.zTest,
                builtinData.backThenFrontRendering,
                builtinData.transparencyFog,
                systemData.renderQueueType
            );

            // Add all shader properties required by the inspector for Tessellation
            if (systemData.tessellation)
                HDSubShaderUtilities.AddTessellationShaderProperties(collector, systemData.tessellationMode,
                    systemData.tessellationFactorMinDistance, systemData.tessellationFactorMaxDistance, systemData.tessellationFactorTriangleSize,
                    systemData.tessellationShapeFactor, systemData.tessellationBackFaceCullEpsilon, systemData.tessellationMaxDisplacement);
        }

        public override void ProcessPreviewMaterial(Material material)
        {
            // Fixup the material settings:
            material.SetFloat(kSurfaceType, (int)systemData.surfaceType);
            material.SetFloat(kDoubleSidedNormalMode, (int)systemData.doubleSidedMode);
            material.SetFloat(kDoubleSidedEnable, systemData.doubleSidedMode != DoubleSidedMode.Disabled ? 1 : 0);
            material.SetFloat(kAlphaCutoffEnabled, systemData.alphaTest ? 1 : 0);
            material.SetFloat(kBlendMode, (int)systemData.blendingMode);
            material.SetFloat(kEnableFogOnTransparent, builtinData.transparencyFog ? 1.0f : 0.0f);
            material.SetFloat(kZTestTransparent, (int)systemData.zTest);
            material.SetFloat(kTransparentCullMode, (int)systemData.transparentCullMode);
            material.SetFloat(kOpaqueCullMode, (int)systemData.opaqueCullMode);
            material.SetFloat(kTransparentZWrite, systemData.transparentZWrite ? 1.0f : 0.0f);

            if (systemData.tessellation)
            {
                material.SetFloat(kTessellationFactorMinDistance, systemData.tessellationFactorMinDistance);
                material.SetFloat(kTessellationFactorMaxDistance, systemData.tessellationFactorMaxDistance);
                material.SetFloat(kTessellationFactorTriangleSize, systemData.tessellationFactorTriangleSize);
                material.SetFloat(kTessellationShapeFactor, systemData.tessellationShapeFactor);
                material.SetFloat(kTessellationBackFaceCullEpsilon, systemData.tessellationBackFaceCullEpsilon);
                material.SetFloat(kTessellationMaxDisplacement, systemData.tessellationMaxDisplacement);
            }

            // No sorting priority for shader graph preview
            material.renderQueue = (int)HDRenderQueue.ChangeType(systemData.renderQueueType, offset: 0, alphaTest: systemData.alphaTest, false);

            ShaderGraphAPI.ValidateLightingMaterial(material);
        }

        internal override void MigrateTo(ShaderGraphVersion version)
        {
            base.MigrateTo(version);

            if (version == ShaderGraphVersion.FirstTimeMigration)
            {
#pragma warning disable 618
                // If we come from old master node, nothing to do.
                // Only perform an action if we are a shader stack
                if (!m_MigrateFromOldSG)
                {
                    builtinData.transparentDepthPrepass = systemData.m_TransparentDepthPrepass;
                    builtinData.transparentDepthPostpass = systemData.m_TransparentDepthPostpass;
                    builtinData.supportLodCrossFade = systemData.m_SupportLodCrossFade;
                }
#pragma warning restore 618
            }
        }
    }
}
