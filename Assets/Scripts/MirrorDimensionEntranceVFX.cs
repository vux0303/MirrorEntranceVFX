using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteAlways]
public class MirrorDimensionEntranceVFX : MonoBehaviour
{
    public MeshFilter stencilMesh;

    public MeshFilter counterClockwiseMesh;

    public MeshFilter clockwiseMesh;


    [Range(1, 5)]
    public int splitFactor = 1;

    [Range(1, 5)]
    public float scale = 1f;

    [Range(1, 20)]
    public int resolution = 8;

    [Range(1, 50)]
    public float rotateSpeed = 1;

    float mostInnerReflectionChange = 0.9f;
    float mostOutterReflectionChange = 0.1f;

    float angleZ = 0;

    private void OnEnable()
    {
        clockwiseMesh.mesh = GenerateCircle();
        counterClockwiseMesh.mesh = GenerateCircle();
        stencilMesh.mesh = GenerateStencil();
    }

    void Update()
    {
        if (!Application.isPlaying)
        {
            return;
        }
        angleZ += rotateSpeed * Time.deltaTime;
        Vector3 clockwiseAngle = clockwiseMesh.gameObject.transform.rotation.eulerAngles;
        Vector3 counterClockwiseAngle = counterClockwiseMesh.gameObject.transform.rotation.eulerAngles;
        clockwiseMesh.gameObject.transform.rotation = Quaternion.Euler(clockwiseAngle.x, clockwiseAngle.y, angleZ);
        counterClockwiseMesh.gameObject.transform.rotation = Quaternion.Euler(counterClockwiseAngle.x, counterClockwiseAngle.y, -angleZ);
    }

    Mesh GenerateStencil()
    {
        var verts = new List<Vector3>();
        var tris = new List<int>();

        verts.Add(Vector3.zero);

        int numPoints = splitFactor * 4;
        float angleStep = Mathf.PI * 2 / (float)numPoints;
        float radius = scale * 1.5f; //to make sure the stencil cover entire mirror mesh

        for (int point = 1; point < numPoints + 1; ++point)
        {
            verts.Add(new Vector2(Mathf.Cos(angleStep * point), Mathf.Sin(angleStep * point)) * radius);
            if (point % 2 == 0)
            {
                tris.Add(0);
                tris.Add(point - 1);
                tris.Add(point);
            }
        }

        var mesh = new Mesh();
        mesh.SetVertices(verts);
        mesh.SetTriangles(tris, 0);
        mesh.RecalculateNormals();
        mesh.UploadMeshData(true);

        return mesh;
    }

    // Get the index of point number 'x' in circle number 'c'
    int GetPointIndex(int c, int x)
    {
        if (c < 0) return 0; // In case of center point
        x = x % ((c + 1) * 6); // Make the point index circular
                               // Explanation: index = number of points in previous circles + central point + x
                               // hence: (0+1+2+...+c)*6+x+1 = ((c/2)*(c+1))*6+x+1 = 3*c*(c+1)+x+1

        return (3 * c * (c + 1) + x + 1);
    }

    float RangeMap(float k)
    {
        return 1 - Mathf.Cos(k * Mathf.PI / 2); //sineIn easing;
        //return k * k * k;
        //return k == 0 ? 0 : Mathf.Pow(2, 10 * k - 10);
    }

    int randomWithPercentage(float per)
    {
        return Random.Range(0, 100) < per * 100 ? 1 : 0;
    }

    public Mesh GenerateCircle()
    { 

        float d = scale / resolution;

        var vtc = new List<Vector3>();
        vtc.Add(Vector3.zero); // Start with only center point
        var tris = new List<int>();
        var colors = new List<Color>();
        colors.Add(new Color(1f, 0.5f, 0.5f));
        float innerCircRadius = 0;

        // First pass => build vertices
        for (int circ = 0; circ < resolution; ++circ)
        {
            float angleStep = (Mathf.PI * 2f) / ((circ + 1) * 6);
            float reflectiveChance = 1 - circ/(float)resolution;
            //Debug.Log("Chance " + reflectiveChance);
            float radius = RangeMap((circ + 1) / (float)resolution) * resolution; //remap step of each circle
            float offsetRange = Mathf.Lerp(0.01f, 0.1f, RangeMap(circ / (float)resolution)); //RangeMap(circ / (float)resolution)
            //Debug.Log("offsetRange " + offsetRange);
            float compensationRadius = radius - innerCircRadius;     //next step range
            innerCircRadius = radius;
            //Debug.Log("radius: " + radius);
            for (int point = 0; point < (circ + 1) * 6; ++point)
            {
                int isReflective = randomWithPercentage(reflectiveChance);
                //Debug.Log("isReflective "+ isReflective);
                float refractionOffset = Random.Range(-offsetRange, offsetRange);
                float reflectionOffset = Random.Range(-offsetRange, offsetRange);
                float radiusDisplacement = Random.Range(0f, compensationRadius * 0.3f) * ((point & 1) * 2 - 1); // to varying radius of each point, make the mesh less uniform
                float angularDisplacement = Random.Range(-angleStep * 0.4f, angleStep * 0.4f);                  // to varying angleStep of each point, make the mesh less uniform
                vtc.Add(new Vector2(
                    Mathf.Cos(angleStep * point + angularDisplacement),
                    Mathf.Sin(angleStep * point + angularDisplacement)
                    ) * d * (radius + radiusDisplacement));
                colors.Add(new Color(isReflective, reflectionOffset, refractionOffset));
            }
        }

        // Second pass => connect vertices into triangles
        for (int circ = 0; circ < resolution; ++circ)
        {
            for (int point = 0, other = 0; point < (circ + 1) * 6; ++point)
            {
                if (point % (circ + 1) != 0)
                {
                    // Create 2 triangles
                    tris.Add(GetPointIndex(circ - 1, other + 1));
                    tris.Add(GetPointIndex(circ - 1, other));
                    tris.Add(GetPointIndex(circ, point));
                    tris.Add(GetPointIndex(circ, point));
                    tris.Add(GetPointIndex(circ, point + 1));
                    tris.Add(GetPointIndex(circ - 1, other + 1));
                    ++other;
                }
                else
                {
                    // Create 1 inverse triange
                    tris.Add(GetPointIndex(circ, point));
                    tris.Add(GetPointIndex(circ, point + 1));
                    tris.Add(GetPointIndex(circ - 1, other));
                    // Do not move to the next point in the smaller circle
                }
            }
        }

        // Create the mesh
        var m = new Mesh();
        m.SetVertices(vtc);
        m.SetTriangles(tris, 0);
        m.SetColors(colors);
        m.RecalculateNormals();
        m.UploadMeshData(true);

        return m;

    }
}
