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

        GrassRenderer grassRenderer = null;
        if(Selection.activeGameObject == null || !Selection.activeGameObject.TryGetComponent(out grassRenderer)) {
            return;
        }
            
        Ray ray = HandleUtility.GUIPointToWorldRay( Event.current.mousePosition );

        if(Physics.Raycast(ray, out var hit))
        {
            Handles.DrawWireDisc(hit.point, hit.normal, radius);
            if (Event.current.type == EventType.MouseDown || Event.current.type == EventType.MouseDrag)
            {
                GUIUtility.hotControl = controlId;
                Event.current.Use();
                Debug.Log(hit.transform.gameObject.name);
                CreatePoints(grassRenderer, hit.point, hit.normal);
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

    private void CreatePoints(GrassRenderer renderer, Vector3 point, Vector3 normal) {
        Vector3[] points = new[] {point};
        for(int i = 0; i < spawnCount; i++) {
           Vector3 a =  UnityEngine.Random.insideUnitCircle;
        }
        renderer.AddPoints(points);
    }
}