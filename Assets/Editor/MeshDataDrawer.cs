using UnityEditor;
using UnityEngine;

[CustomPropertyDrawer(typeof(MeshData))]
public class MeshDataDrawer : PropertyDrawer
{
    private Editor _meshPreviewEditor;
    private Mesh _lastMesh;

    public override void OnGUI(Rect position, SerializedProperty property, GUIContent label)
    {
        SerializedProperty nameProp = property.FindPropertyRelative("Name");
        SerializedProperty idProp = property.FindPropertyRelative("Id");
        SerializedProperty meshRefProp = property.FindPropertyRelative("meshReference");
        SerializedProperty materialsProp = property.FindPropertyRelative("SubMeshMaterials");

        string meshName = string.IsNullOrEmpty(nameProp.stringValue) ? "Unnamed Mesh" : nameProp.stringValue;
        string displayName = $"{meshName} (ID: {idProp.intValue})";

        Rect foldoutRect = new Rect(position.x, position.y, position.width, EditorGUIUtility.singleLineHeight);
        property.isExpanded = EditorGUI.Foldout(foldoutRect, property.isExpanded, displayName, true);

        if (!property.isExpanded) return;

        EditorGUI.indentLevel++;

        float currentY = position.y + EditorGUIUtility.singleLineHeight + 2;

        currentY = DrawPropertyField(currentY, position.width, nameProp);
        currentY = DrawPropertyField(currentY, position.width, idProp);
        currentY = DrawPropertyField(currentY, position.width, meshRefProp);
        currentY = DrawPropertyField(currentY, position.width, materialsProp);

        DrawMeshPreview(currentY, position.width, meshRefProp);

        EditorGUI.indentLevel--;
    }

    private float DrawPropertyField(float y, float width, SerializedProperty prop)
    {
        float height = EditorGUI.GetPropertyHeight(prop, true);
        Rect rect = new Rect(EditorGUI.IndentedRect(new Rect(0, y, width, height)));
        EditorGUI.PropertyField(rect, prop, true);
        return y + height + 2;
    }

    private void DrawMeshPreview(float y, float width, SerializedProperty meshRefProp)
    {
        SerializedProperty assetProp = meshRefProp.FindPropertyRelative("m_Asset");
        Mesh currentMesh = (assetProp != null) ? assetProp.objectReferenceValue as Mesh : null;

        if (currentMesh == null) return;

        if (_meshPreviewEditor == null || _lastMesh != currentMesh)
        {
            _lastMesh = currentMesh;
            Editor.CreateCachedEditor(currentMesh, null, ref _meshPreviewEditor);
        }

        if (_meshPreviewEditor != null)
        {
            Rect totalRect = EditorGUI.IndentedRect(new Rect(0, y + 5, width, 150));

            Rect labelRect = new Rect(totalRect.x, totalRect.y, EditorGUIUtility.labelWidth, EditorGUIUtility.singleLineHeight);
            Rect previewRect = new Rect(totalRect.x + EditorGUIUtility.labelWidth, totalRect.y, totalRect.width - EditorGUIUtility.labelWidth, 140);

            EditorGUI.LabelField(labelRect, "Mesh Preview");
            GUI.Box(previewRect, GUIContent.none, EditorStyles.helpBox);
            _meshPreviewEditor.OnInteractivePreviewGUI(previewRect, EditorStyles.whiteLabel);
        }
    }

    public override float GetPropertyHeight(SerializedProperty property, GUIContent label)
    {
        if (!property.isExpanded) return EditorGUIUtility.singleLineHeight;

        float height = EditorGUIUtility.singleLineHeight + 4;
        height += EditorGUI.GetPropertyHeight(property.FindPropertyRelative("Name"), true) + 2;
        height += EditorGUI.GetPropertyHeight(property.FindPropertyRelative("Id"), true) + 2;
        height += EditorGUI.GetPropertyHeight(property.FindPropertyRelative("meshReference"), true) + 2;
        height += EditorGUI.GetPropertyHeight(property.FindPropertyRelative("SubMeshMaterials"), true) + 2;

        SerializedProperty assetProp = property.FindPropertyRelative("meshReference.m_Asset");
        if (assetProp != null && assetProp.objectReferenceValue is Mesh)
        {
            height += 145;
        }

        return height;
    }
}
