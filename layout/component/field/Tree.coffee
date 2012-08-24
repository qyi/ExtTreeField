Ext.define "Krypton.lib.layout.component.field.Tree"
    extend: "Ext.layout.component.field.Field"
    
    alias: "layout.treefield"
    
    type: "treefield"
    
    afterLayout: (width, height) ->
        @owner.tree.getView().resetScrollers()
        
    sizeBodyContents: (width, height) ->
        @callParent arguments
        @owner.tree.setWidth width