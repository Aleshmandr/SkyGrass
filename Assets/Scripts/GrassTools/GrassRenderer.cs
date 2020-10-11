using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

[ExecuteInEditMode, RequireComponent(typeof(MeshRenderer), typeof(MeshFilter))]
public class GrassRenderer : MonoBehaviour {
    private MeshFilter _meshFilter;
    private MeshRenderer _renderer;
    private MeshRenderer _mesh;
    private List<Vector3> vertices = new List<Vector3>();

    private MeshFilter MeshFilter {
        get {
            if(_meshFilter == null) {
                _meshFilter = GetComponent<MeshFilter>();
            }
            return _meshFilter;
        }
    }

    private Mesh Mesh {
        get {
            if(MeshFilter.sharedMesh == null) {
                MeshFilter.mesh = new Mesh {indexFormat = IndexFormat.UInt32};
            }
            return MeshFilter.sharedMesh;
        }
    }

    private MeshRenderer Renderer {
        get {
            if(_renderer == null) {
                _renderer = GetComponent<MeshRenderer>();
            }
            return _renderer;
        }
    }

    public void AddPoints(Vector3[] points) {
        Mesh.GetVertices(vertices);
        for(int i = 0; i < points.Length; i++) {
            points[i] = transform.InverseTransformPoint(points[i]);
        }
        vertices.AddRange(points);
        Mesh.SetVertices(vertices);
        int[] indices = new int[vertices.Count];
        for(int i = 0; i < indices.Length; i++) {
            indices[i] = i;
        }
        Mesh.SetIndices(indices, MeshTopology.Points, 0);
    }
}