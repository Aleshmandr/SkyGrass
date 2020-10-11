//
// created by jiadong chen
// http://www.chenjd.me
//

using UnityEngine;
using System.Collections.Generic;
using UnityEngine.Rendering;

public class GrassMeshGenerator : MonoBehaviour {
    [SerializeField] private MeshFilter ground;
    [SerializeField] private Material material;
    [SerializeField, Min(0)] private int grassCount;
    [SerializeField, Min(0)] private int grassPerIteration;
    private List<Vector3> verts = new List<Vector3>();

    void Start() {
        GenerateGrassMesh();
    }

    private void GenerateGrassMesh() {
        MeshFilter meshFilter = gameObject.AddComponent<MeshFilter>();
        MeshRenderer meshRenderer = gameObject.AddComponent<MeshRenderer>();
        meshRenderer.material = material;
        Mesh grassMesh = new Mesh {indexFormat = IndexFormat.UInt32};
        meshFilter.mesh = grassMesh;
        Mesh groundMesh = ground.mesh;

        int grassCounter = 0;
        int trisCount = groundMesh.triangles.Length / 3;
        var inidices = groundMesh.GetIndices(0);
        Debug.Log($"Tris count ={trisCount}");
        Vector3[] vertices = new Vector3[grassCount];
        int[] indices = new int[grassCount];

        int trisCounter = 0;
        while(grassCounter < grassCount) {
            int randomTriangleIndex = (trisCounter * 3)%groundMesh.triangles.Length;
            trisCounter++;
            var point1 = groundMesh.vertices[groundMesh.triangles[randomTriangleIndex]];
            var point2 = groundMesh.vertices[groundMesh.triangles[randomTriangleIndex + 1]];
            var point3 = groundMesh.vertices[groundMesh.triangles[randomTriangleIndex + 2]];
            Vector3 dir1 = point2 - point1;
            Vector3 dir2 = point3 - point1;
            for(int i = 0; i < grassPerIteration; i++) {
                Vector3 randomDir = Vector3.Lerp(dir1, dir2, Random.value);
                Vector3 randomVert = point1 + randomDir * Random.value;
                vertices[grassCounter] = randomVert;
                indices[grassCounter] = grassCounter;
                grassCounter++;
            }
        }
        grassMesh.SetVertices(vertices);
        grassMesh.SetIndices(indices, MeshTopology.Points, 0);
    }
    
    private void GenerateGrassMesh2() {
        MeshFilter meshFilter = gameObject.AddComponent<MeshFilter>();
        MeshRenderer meshRenderer = gameObject.AddComponent<MeshRenderer>();
        meshRenderer.material = material;
        Mesh grassMesh = new Mesh {indexFormat = IndexFormat.UInt32};
        meshFilter.mesh = grassMesh;
        Mesh groundMesh = ground.mesh;

        int grassCounter = 0;
        int trisCount = groundMesh.triangles.Length / 3;
        var inidices = groundMesh.GetIndices(0);
        Debug.Log($"Tris count ={trisCount}");
        Vector3[] vertices = new Vector3[grassCount];
        int[] indices = new int[grassCount];

        int trisCounter = 0;
        while(grassCounter < grassCount) {
            int randomTriangleIndex = (trisCounter * 3)%groundMesh.triangles.Length;
            trisCounter++;
            var point1 = groundMesh.vertices[groundMesh.triangles[randomTriangleIndex]];
            var point2 = groundMesh.vertices[groundMesh.triangles[randomTriangleIndex + 1]];
            var point3 = groundMesh.vertices[groundMesh.triangles[randomTriangleIndex + 2]];
            
            for(int i = 0; i < grassPerIteration; i++) {
                Vector3 mid1 = Vector3.Lerp(point1, point2, Random.value);
                Vector3 mid2 = Vector3.Lerp(point2, point3, Random.value);
                Vector3 mid3 = Vector3.Lerp(point3, point1, Random.value);
                Vector3 mid = (mid1 + mid2 + mid3) * 0.3333f;
                
                vertices[grassCounter] = mid;
                indices[grassCounter] = grassCounter;
                grassCounter++;
            }
        }
        grassMesh.SetVertices(vertices);
        grassMesh.SetIndices(indices, MeshTopology.Points, 0);
    }
}