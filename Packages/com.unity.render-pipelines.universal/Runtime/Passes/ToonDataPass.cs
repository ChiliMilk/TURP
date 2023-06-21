using System;
using UnityEngine.Experimental.Rendering;
using UnityEngine.Experimental.Rendering.RenderGraphModule;

namespace UnityEngine.Rendering.Universal.Internal
{
    public class ToonDataPass : ScriptableRenderPass
    {
        private static readonly ShaderTagId k_ShaderTagId = new ShaderTagId("ToonData");
        private RTHandle colorDestination { get; set; }
        private RTHandle depthDestination { get; set; }
        FilteringSettings m_FilteringSettings;

        public ToonDataPass(RenderPassEvent evt, RenderQueueRange renderQueueRange, LayerMask layerMask)
        {
            m_FilteringSettings = new FilteringSettings(renderQueueRange, layerMask);
            renderPassEvent = evt;
        }

        public void Setup(RTHandle colorAttachmentHandle, RTHandle depthAttachmentHandle)
        {
            this.colorDestination = colorAttachmentHandle;
            this.depthDestination = depthAttachmentHandle;
        }

        public override void OnCameraSetup(CommandBuffer cmd, ref RenderingData renderingData)
        {
            ConfigureTarget(colorDestination, depthDestination);
            ConfigureClear(ClearFlag.All, Color.black);
        }

        public override void Execute(ScriptableRenderContext context, ref RenderingData renderingData)
        {
            var cmd = renderingData.commandBuffer;

            using (new ProfilingScope(cmd, new ProfilingSampler("ToonData")))
            {
                context.ExecuteCommandBuffer(cmd);
                cmd.Clear();

                var sortFlags = renderingData.cameraData.defaultOpaqueSortFlags;
                var drawSettings = RenderingUtils.CreateDrawingSettings(k_ShaderTagId, ref renderingData, sortFlags);
                drawSettings.perObjectData = PerObjectData.None;

                context.DrawRenderers(renderingData.cullResults, ref drawSettings, ref m_FilteringSettings);
            }
        }
    }
}
