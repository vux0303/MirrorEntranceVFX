using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
public class PlanarReflection : MonoBehaviour
{
    // referenses
    Camera mainCamera;
    Camera reflectionCamera;
    GameObject reflectionPlane;
    public Material reflectiveMat1;
    public Material reflectiveMat2;
    RenderTexture outputTexture;

    private void Start()
    {
        reflectionPlane = gameObject;

        GameObject reflectionCameraNode = new GameObject();
        reflectionCamera = reflectionCameraNode.AddComponent<Camera>();
        reflectionCamera.enabled = true;

        mainCamera = Camera.main;

        outputTexture = new RenderTexture(Screen.width, Screen.height, 24);

        RenderPipelineManager.beginCameraRendering += OnBeginCameraRendering;
    }

    private void OnDisable()
    {
        RenderPipelineManager.beginCameraRendering -= OnBeginCameraRendering;
    }

    private void OnBeginCameraRendering(ScriptableRenderContext context, Camera camera)
    {
        OnCameraPreRendering();
    }

    private void OnCameraPreRendering()
    {
        RenderReflection();
    }

    private void RenderReflection()
    {
        reflectionCamera.CopyFrom(mainCamera);

        // take main camera directions and position world space
        Vector3 cameraDirectionWorldSpace = mainCamera.transform.forward;
        Vector3 cameraUpWorldSpace = mainCamera.transform.up;
        Vector3 cameraPositionWorldSpace = mainCamera.transform.position;

        // transform direction and position by reflection plane
        Vector3 cameraDirectionPlaneSpace = reflectionPlane.transform.InverseTransformDirection(cameraDirectionWorldSpace);
        Vector3 cameraUpPlaneSpace = reflectionPlane.transform.InverseTransformDirection(cameraUpWorldSpace);
        Vector3 cameraPositionPlaneSpace = reflectionPlane.transform.InverseTransformPoint(cameraPositionWorldSpace);

        // invert direction and position by reflection plane
        cameraDirectionPlaneSpace.z *= -1;
        cameraUpPlaneSpace.z *= -1;
        cameraPositionPlaneSpace.z *= -1;

        // transform direction and position from reflection plane local space to world space
        cameraDirectionWorldSpace = reflectionPlane.transform.TransformDirection(cameraDirectionPlaneSpace);
        cameraUpWorldSpace = reflectionPlane.transform.TransformDirection(cameraUpPlaneSpace);
        cameraPositionWorldSpace = reflectionPlane.transform.TransformPoint(cameraPositionPlaneSpace);

        // apply direction and position to reflection camera
        reflectionCamera.transform.position = cameraPositionWorldSpace;
        reflectionCamera.transform.LookAt(cameraPositionWorldSpace + cameraDirectionWorldSpace, cameraUpWorldSpace);

        // Set the camera's oblique view frustum.
        Plane p = new Plane(-cameraDirectionWorldSpace, reflectionPlane.transform.position);
        Vector4 clipPlane = new Vector4(p.normal.x, p.normal.y, p.normal.z, p.distance);
        Vector4 clipPlaneCameraSpace =
            Matrix4x4.Transpose(Matrix4x4.Inverse(reflectionCamera.worldToCameraMatrix)) * clipPlane;

        var newMatrix = mainCamera.CalculateObliqueMatrix(clipPlaneCameraSpace);
        reflectionCamera.projectionMatrix = newMatrix;

        reflectionCamera.targetTexture = outputTexture;

        reflectiveMat1.SetTexture("_ReflectionTex", outputTexture);
        reflectiveMat2.SetTexture("_ReflectionTex", outputTexture);
    }
}
