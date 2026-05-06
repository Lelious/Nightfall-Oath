using System;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.RenderGraphModule;
using UnityEngine.Rendering.Universal;

public class FogFeature : ScriptableRendererFeature
{
    class FogPass : ScriptableRenderPass
    {
        Material material;

        public FogPass(Material mat)
        {
            material = mat;
            renderPassEvent = RenderPassEvent.BeforeRenderingPostProcessing;
        }

        public override void RecordRenderGraph(RenderGraph renderGraph, ContextContainer frameData)
        {
            var resources = frameData.Get<UniversalResourceData>();

            TextureHandle source = resources.activeColorTexture;

            using (var builder = renderGraph.AddRasterRenderPass<PassData>(
                "AAA Fog", out var passData))
            {
                passData.src = source;
                passData.mat = material;

                builder.UseTexture(source, AccessFlags.Read);

                builder.SetRenderAttachment(source, 0);

                builder.SetRenderFunc((PassData data, RasterGraphContext ctx) =>
                {
                    data.mat.SetTexture("_BlitTexture", data.src);
                    data.mat.SetTexture("_CameraDepthTexture", data.src);

                    CoreUtils.DrawFullScreen(ctx.cmd, data.mat);
                });
            }
        }

        class PassData
        {
            public TextureHandle src;
            public Material mat;
        }
    }

    public Material fogMaterial;
    FogPass pass;

    public override void Create()
    {
        pass = new FogPass(fogMaterial);
    }

    public override void AddRenderPasses(ScriptableRenderer renderer, ref RenderingData renderingData)
    {
        if (fogMaterial == null) return;
        renderer.EnqueuePass(pass);
    }
}
