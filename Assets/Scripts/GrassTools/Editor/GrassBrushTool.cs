using System;
using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEditor.EditorTools;
using UnityEngine;
using UnityEngine.Serialization;

[EditorTool("Grass Tool")]
public class GrassBrushTool : EditorTool
{
    // Serialize this value to set a default value in the Inspector.
    [SerializeField] private Texture2D toolIcon;
    private int controlId;
    
    private GUIContent iconContent;

    private void OnEnable()
    {
        controlId = GUIUtility.GetControlID(FocusType.Passive);
        iconContent = new GUIContent()
        {
            image = toolIcon,
            text = "Grass Tool",
            tooltip = "Grass Tool"
        };
    }

    private void OnDisable()
    {
        controlId = 0;
    }

    public override GUIContent toolbarIcon
    {
        get { return iconContent; }
    }

    // This is called for each window that your tool is active in. Put the functionality of your tool here.
    public override void OnToolGUI(EditorWindow window)
    {
     
        EditorGUI.BeginChangeCheck();

        Vector3 position = Tools.handlePosition;
        
        Ray ray = HandleUtility.GUIPointToWorldRay( Event.current.mousePosition );
         
        RaycastHit hit;
        if( Physics.Raycast( ray, out hit ) )
        {
            Handles.DrawWireDisc(hit.point, hit.normal, 1);
            if (Event.current.type == EventType.MouseDown)
            {
                GUIUtility.hotControl = controlId;
                Event.current.Use();
                Debug.Log(hit.transform.gameObject.name);
            }
        }
        

        using (new Handles.DrawingScope(Color.green))
        {
            position = Handles.Slider(position, Vector3.right);
        }

        if (EditorGUI.EndChangeCheck())
        {
            Vector3 delta = position - Tools.handlePosition;

            Undo.RecordObjects(Selection.transforms, "Move Platform");

            foreach (var transform in Selection.transforms)
                transform.position += delta;
        }
    }
}