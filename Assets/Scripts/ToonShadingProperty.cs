using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteAlways]
public class ToonShadingProperty : MonoBehaviour
{
    [SerializeField] Transform mainLight;
    [SerializeField] float ToonPointShadowOffsetDistance = 1f;
    [SerializeField] Transform ToonPointShadowPosition;
    List<Material> materialsStaticMesh;
    List<Material> materialsSkinMesh;

    [SerializeField] Material ToonSDFShadowFaceMaterial;
    [SerializeField] Transform ToonSDFGameObject;
    [SerializeField] Vector3 ToonSDFObjectForward = new Vector3(0, 0, 1);
    [SerializeField] Vector3 ToonSDFObjectLeft = new Vector3(-1, 0, 0);
    void OnEnable()
    {
        materialsStaticMesh = new List<Material>();
        var staticMeshs = GetComponentsInChildren<MeshRenderer>();
        foreach (var mesh in staticMeshs)
        {
            foreach(Material material in mesh.sharedMaterials)
            {
                materialsStaticMesh.Add(material);
            }
        }

        materialsSkinMesh = new List<Material>();
        var skinMeshs = GetComponentsInChildren<SkinnedMeshRenderer>();
        foreach (var mesh in skinMeshs)
        {
            foreach (Material material in mesh.sharedMaterials)
            {
                materialsSkinMesh.Add(material);
            }
        }
    }

    // Update is called once per frame
    void LateUpdate()
    {
        if(mainLight != null)
        {
            Vector3 offsetVec = -mainLight.forward * ToonPointShadowOffsetDistance;

            if (materialsStaticMesh != null && materialsStaticMesh.Count > 0 && ToonPointShadowPosition != null)
            {
                foreach (var material in materialsStaticMesh)
                {
                    material.SetVector("_ToonPointShadowPosition", ToonPointShadowPosition.position + offsetVec);
                }
            }
            if (materialsSkinMesh != null && materialsSkinMesh.Count > 0 && ToonPointShadowPosition != null)
            {
                foreach (var material in materialsSkinMesh)
                {
                    material.SetVector("_ToonPointShadowPosition", ToonPointShadowPosition.position + offsetVec);
                }
            }

            if(ToonSDFShadowFaceMaterial !=null && ToonSDFGameObject != null)
            {
                Vector2 lightDirectionXZ = new Vector2(-mainLight.transform.forward.x, -mainLight.transform.forward.z);
                Vector3 forwardWS = ToonSDFGameObject.transform.TransformDirection(ToonSDFObjectForward);
                Vector3 leftWS = ToonSDFGameObject.transform.TransformDirection(ToonSDFObjectLeft);

                Vector2 forwardXZ = new Vector2(forwardWS.x, forwardWS.z);
                Vector2 leftXZ = new Vector2(leftWS.x, leftWS.z);

                lightDirectionXZ.Normalize();
                forwardXZ.Normalize();
                leftXZ.Normalize();

                ToonSDFShadowFaceMaterial.SetVector("_ToonSDFShadowLdotFL", new Vector2(Vector2.Dot(lightDirectionXZ, forwardXZ), Vector2.Dot(lightDirectionXZ, leftXZ)));
            }
        }
    }
}
