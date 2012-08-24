
Ext.define "Krypton.lib.form.field.Tree"
    extend: "Ext.form.field.Base"
    
    alias: "widget.treefield"
    
    requires: [ "Ext.tree.Panel" ]
    
    fieldSubTpl: [
        '<input id="{id}" type="{type}" style="height:1px; border: 0px solid transparent; background: transparent;"',
        '<tpl if="name">name="{name}" </tpl>',
        '<tpl if="size">size="{size}" </tpl>',
        '<tpl if="tabIdx">tabIndex="{tabIdx}" </tpl>',
        'class="{fieldCls} {typeCls}" autocomplete="off" />',
        {
            compiled: true,
            disableFormats: true
        }
    ]
    
    componentLayout: "treefield"
    
    tree: false
    
    height: 150
    
    border: false
    
    root: null
    
    displayField: "text"
    
    valueField: "text"
    
    rootVisible: false
    
    appendOnly: false
    
    allowBlank: true
    
    minSelections: 0
    
    maxSelections: Number.MAX_VALUE
    
    blankText: "This field is required"
    
    minSelectionsText: "Minimum {0} items(s) required"
    
    maxSelectionsText: "Maximum {0} item(s) allowed"
    
    focusCls: false
    
    fieldBodyCls: Ext.baseCSSPrefix + "form-tree-body"
    
    initComponent: ->
        @bindStore @store, true
        @callParent arguments
        
    initEvents: ->
        @callParent arguments
        @mun(@inputEl, "blur", @onBlur, @, if @inEditor then buffer: 10 else null)
        
        if typeof (viewEl = @tree.getView().el) == "object"
            @mon(viewEl, "blur", @onBlur, @, if @inEditor then buffer: 10 else null)
            
    bindStore: (store, initial) ->
        oldStore = @store;
        tree = @tree;
        
        if oldStore && !initial && oldStore != store && oldStore.autoDestroy
            oldStore.destroy()
        
        @store = if store then Ext.data.StoreManager.lookup store else null
        if tree
            tree.bindStore store || null
            
    onRender: (ct, position) ->
        @callParent arguments
        
        tree = @tree = Ext.create "Ext.tree.Panel"
            multiSelect: if @multiSelect then @multiSelect else true
            fields: @fields
            store: @store
            root: @root
            displayField: @displayField
            valueField: @valueField
            renderTo: @bodyEl
            height: @height
            rootVisible: @rootVisible
            autoScroll: true
            ownerLayout: @getComponentLayout()            
            border: false
            style:
                width: '100%' #view as byke
                border: '1px solid #d2d2d2'
        
        @mon tree.getSelectionModel(),
            selectionChange: @onSelectionChange
            scope: @
        
        tree.ownerCt = @
        
        @setRawValue @rawValue
        
    onSelectionChange: ->
        @checkChange()
        
    clearValue: ->
        @setValue []
        
    setRawValue: (value) ->        
        #value = Ext.Array.from value
        @rawValue = value
        return
        if @tree
            root = @tree.getRootNode()
            if root
                models = []
                Ext.Array.forEach value, (val) ->
                    if model = root.findChild @valueField, val, true
                        models.push model
                @tree.getSelectionModel().select models, false, true
                
        return value
            
    getRawValue: ->
        if tree = @tree
            valueField = @valueField
            @rawValue = Ext.Array.map tree.getSelectionModel().getSelection(), (model) ->
                return model.get valueField            
        return @rawValue
            
    getValue: ->  
        val = @rawToValue(@processRawValue(@getRawValue()))
        if val.length == 1
            val = val[0]
        else if val.length == 0
            val = ''
        @value = val
        return val
     
    reset: ->
        @callParent()
        @applyEmptyText()
    
    applyEmptyText: ->
        @tree.getSelectionModel().deselectAll()
        
    valueToRaw: (value) ->
        return value
        
    isEqual: (v1, v2) ->
        fromArray = Ext.Array.from
        
        v1 = fromArray v1
        v2 = fromArray v2
        
        if len = v1.length != v2.length
            return false
            
        for i in len
            if v2[i] != v1[i]
                return false
        
        return true
        
    getErrors: (value) ->
        format = Ext.String.format
        errors = @callParent arguments
        
        value = Ext.Array.from value || @getValue()
        numSelected = value.length
        
        if !@allowBlank && numSelected < 1
            errors.push @blankText
            
        if numSelected < @minSelections
            errors.push format @minSelectionsText, @minSelections
            
        if numSelected > @maxSelections
            errors.push format @maxSelectionsText, @maxSelections
            
        return errors
        
    onDisable: ->
        @callParent()
        @disabled = true        
        @updateReadOnly()
                
    onEnable: ->
        @callParent()
        @disabled = false
        @updateReadOnly()
        
    setReadOnly: (readOnly)->
        @readOnly = readOnly
        @updateReadOnly()
        
    updateReadOnly: ->
        if @tree
            readOnly = @readOnly || @disabled
            @tree.getSelectionModel().setLocked readOnly
            
    onDestroy: ->        
        Ext.destroyMembers @, "tree"
        @callParent()
        
    onFocus: ->        
        @preFocus()
        #if @focusCls && inputEl
        #    ""
            
        unless @hasFocus
            @hasFocus = true
            selection = @tree.getSelectionModel().getSelection()
            @fireEvent "focus", @
            
            @tree.getView().el.focus()
            
            if typeof selection[0] == "undefined" && !@allowBlank
                @tree.getSelectionModel().select(0)
                
    onBlur: ->
        @beforeBlur()
        if @validateOnBlur
            @validate()
        @hasFocus = false
        @fireEvent "blur", @
        @postBlur()
        
    getFocusEl: ->
        return @tree.getView().el