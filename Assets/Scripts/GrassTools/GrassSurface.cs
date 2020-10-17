using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

[ExecuteInEditMode, RequireComponent(typeof(MeshRenderer), typeof(MeshFilter))]
public class GrassSurface : MonoBehaviour
{
    [SerializeField] private float minGrassSpaceDistance = 0.05f;
    private MeshFilter _meshFilter;
    private MeshRenderer _renderer;
    private MeshRenderer _mesh;
    private List<Vector3> vertices = new List<Vector3>();
    private PointOctree<int> pointsTree;
    private bool needRebuildTree = true;

    private MeshFilter MeshFilter
    {
        get
        {
            if (_meshFilter == null)
            {
                _meshFilter = GetComponent<MeshFilter>();
            }

            return _meshFilter;
        }
    }

    public Mesh Mesh
    {
        get
        {
            if (MeshFilter.sharedMesh == null)
            {
                MeshFilter.mesh = new Mesh {indexFormat = IndexFormat.UInt32};
                needRebuildTree = true;
            }

            return MeshFilter.sharedMesh;
        }
    }

    private MeshRenderer Renderer
    {
        get
        {
            if (_renderer == null)
            {
                _renderer = GetComponent<MeshRenderer>();
            }

            return _renderer;
        }
    }

    private void OnValidate()
    {
        needRebuildTree = true;
    }

    public void RemovePoints(Vector3 worldPos, float radius)
    {
        RebuildTreeIfNeed();
        Mesh.GetVertices(vertices);
        var removePoints = pointsTree.GetNearby(transform.InverseTransformPoint(worldPos), radius);
        Array.Sort(removePoints);
        for (int i = 0; i < removePoints.Length; i++)
        {
            pointsTree.Remove(removePoints[i]);
            vertices.RemoveAt(removePoints[i]-i);
        }

        UpdateMesh(vertices);
    }

    public void AddPoints(Vector3[] newPoints)
    {
        RebuildTreeIfNeed();
        Mesh.GetVertices(vertices);

        float minSqrDist = minGrassSpaceDistance * minGrassSpaceDistance;
        for (int i = 0; i < newPoints.Length; i++)
        {
            float nearstSqrDistance = float.MaxValue;
            Vector3 newPointLocalPos = transform.InverseTransformPoint(newPoints[i]);
            pointsTree.GetNearest(newPointLocalPos, ref nearstSqrDistance);
            if (nearstSqrDistance > minSqrDist && pointsTree.TryAdd(vertices.Count, newPoints[i]))
            {
                vertices.Add(newPointLocalPos);
            }
        }

        UpdateMesh(vertices);
    }

    private void UpdateMesh(List<Vector3> newVertices)
    {
        Mesh.triangles = null;
        Mesh.SetVertices(newVertices);
        int[] indices = new int[newVertices.Count];
        for (int i = 0; i < indices.Length; i++)
        {
            indices[i] = i;
        }

        Mesh.SetIndices(indices, MeshTopology.Points, 0);
    }

    private void RebuildTreeIfNeed()
    {
        if (needRebuildTree || pointsTree == null || pointsTree.Count != Mesh.vertices.Length)
        {
            Mesh.GetVertices(vertices);
            var newVertices = new List<Vector3>();
            pointsTree = new PointOctree<int>(10, transform.position, 0.1f);
            for (int i = 0; i < vertices.Count; i++)
            {
                if (pointsTree.TryAdd(i, vertices[i]))
                {
                    newVertices.Add(vertices[i]);
                }
            }

            UpdateMesh(newVertices);
        }
    }
}