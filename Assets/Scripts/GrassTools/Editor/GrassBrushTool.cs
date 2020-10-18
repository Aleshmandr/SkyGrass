using System;
using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEditor.EditorTools;
using UnityEngine;
using UnityEngine.Serialization;
using Random = System.Random;

[EditorTool("Grass Tool")]
public class GrassBrushTool : EditorTool
{
    // Serialize this value to set a default value in the Inspector.
    [SerializeField] private Texture2D toolIcon;
    private GUIContent iconContent;
    private int spawnCount = 10;
    private float radius = 1f;
    private int controlId;

    public override GUIContent toolbarIcon => iconContent;

    private void OnEnable()
    {
        Debug.Log("Brush enable");

        controlId = GUIUtility.GetControlID(FocusType.Passive);
        iconContent = new GUIContent()
        {
            image = toolIcon,
            text = "Grass Tool",
            tooltip = "Grass Tool"
        };
    }

    // This is called for each window that your tool is active in. Put the functionality of your tool here.
    public override void OnToolGUI(EditorWindow window)
    {
        EditorGUI.BeginChangeCheck();

        if (Selection.activeGameObject == null ||
            !Selection.activeGameObject.TryGetComponent(out GrassSurface grassRenderer) || grassRenderer.Mesh == null)
        {
            return;
        }

        Ray ray = HandleUtility.GUIPointToWorldRay(Event.current.mousePosition);

        if (Physics.Raycast(ray, out var hit))
        {
            Handles.DrawWireDisc(hit.point, hit.normal, radius);
            if (Event.current.button == 0
                && (Event.current.type == EventType.MouseDown || Event.current.type == EventType.MouseDrag))
            {
                GUIUtility.hotControl = controlId;
                Event.current.Use();

                if (Event.current.shift)
                {
                    grassRenderer.RemovePoints(hit.point, radius);
                }
                else
                {
                    CreatePoints(grassRenderer, hit.point, hit.normal);
                }
            }
        }


        //using (new Handles.DrawingScope(Color.green))
        //{
        //    position = Handles.Slider(position, Vector3.right);
        //}

        if (EditorGUI.EndChangeCheck())
        {
            //Vector3 delta = position - Tools.handlePosition;
            //Undo.RecordObjects(Selection.transforms, "Move Platform");
            //foreach (var transform in Selection.transforms)
            //    transform.position += delta;
        }
    }


    private void CreatePoints(GrassSurface grassSurface, Vector3 point, Vector3 normal)
    {
        List<Vector3> newPoints =new List<Vector3>();
        for (int i = 0; i < spawnCount; i++)
        {
            Vector3 grassPos = UnityEngine.Random.insideUnitCircle * radius;
            Quaternion rotation = Quaternion.FromToRotation(Vector3.forward, normal);
            grassPos = point + rotation * grassPos;
            Vector3 rayPos = grassPos + normal * radius;
            Ray grassRay =  new Ray(rayPos, -normal);
            if (Physics.Raycast(grassRay, out RaycastHit hitInfo, radius * 2))
            {
                newPoints.Add(hitInfo.point);
            }
        }
        grassSurface.AddPoints(newPoints.ToArray());
    }
}