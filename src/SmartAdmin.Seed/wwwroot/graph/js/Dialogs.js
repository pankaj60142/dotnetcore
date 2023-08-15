/**
 * Copyright (c) 2006-2012, JGraph Ltd
 */
/**
 * Constructs a new open dialog.
 */
var OpenDialog = function () {
    var iframe = document.createElement('iframe');
    iframe.style.backgroundColor = 'transparent';
    iframe.allowTransparency = 'true';
    iframe.style.borderStyle = 'none';
    iframe.style.borderWidth = '0px';
    iframe.style.overflow = 'hidden';
    iframe.frameBorder = '0';

    var dx = 0;
    iframe.setAttribute('width', (((Editor.useLocalStorage) ? 640 : 320) + dx) + 'px');
    iframe.setAttribute('height', (((Editor.useLocalStorage) ? 480 : 220) + dx) + 'px');
    iframe.setAttribute('src', OPEN_FORM);

    this.container = iframe;
};

function validateEmail(email) {
    var re = /\S+@\S+\.\S+/;
    return re.test(email);
}
var AddShareViaEmailDialog = function (editorUi) {



    //div.appendChild(iframe);


    if (editorUi.editor.filename == null) {
        alert('No Diagram to email..Please save the diagram first');
        return;
    }

    var div = document.createElement('div');
    mxUtils.write(div, mxResources.get('shareviaEmail') + ':');

    var inner = document.createElement('div');
    inner.className = 'geTitle';
    inner.style.backgroundColor = 'transparent';
    inner.style.borderColor = 'transparent';
    inner.style.whiteSpace = 'nowrap';
    inner.style.textOverflow = 'clip';
    inner.style.cursor = 'default';
    inner.style.paddingRight = '20px';

    var linkInput = document.createElement('input');
   
    linkInput.setAttribute('placeholder', 'enter email address to share');
    linkInput.setAttribute('type', 'text');
    linkInput.style.marginTop = '6px';
    linkInput.style.width = '400px';
    linkInput.style.backgroundImage = 'url(\'' + Dialog.prototype.clearImage + '\')';
    linkInput.style.backgroundRepeat = 'no-repeat';
    linkInput.style.backgroundPosition = '100% 50%';
    linkInput.style.paddingRight = '14px';

    var cross = document.createElement('div');
    cross.setAttribute('title', mxResources.get('reset'));
    cross.style.position = 'relative';
    cross.style.left = '-16px';
    cross.style.width = '12px';
    cross.style.height = '14px';
    cross.style.cursor = 'pointer';

    // Workaround for inline-block not supported in IE
    cross.style.display = 'inline-block';
    cross.style.top = '3px';

    // Needed to block event transparency in IE
    cross.style.background = 'url(' + IMAGE_PATH + '/transparent.gif)';

    const para = document.createElement("p");
    para.innerText = "";
    para.style.color = "red";

    mxEvent.addListener(cross, 'click', function () {
        linkInput.value = '';
        linkInput.focus();
    });

    inner.appendChild(linkInput);
    inner.appendChild(cross);
    inner.appendChild(para);
    div.appendChild(inner);

    this.init = function () {
        linkInput.focus();

        if (mxClient.IS_GC || mxClient.IS_FF || document.documentMode >= 5) {
            linkInput.select();
        }
        else {
            document.execCommand('selectAll', false, null);
        }
    };

    var btns = document.createElement('div');
    btns.style.marginTop = '18px';
    btns.style.textAlign = 'right';

    mxEvent.addListener(linkInput, 'keypress', function (e) {
        if (e.keyCode == 13) {
            var rooturl = rootUrl;
            if (validateEmail(linkInput.value)) {
                para.style.color = "orange";
                para.innerText = "Processing...";
                var compid = localStorage.getItem("companyid");
                $.ajax({
                    url: '../Graph/ShareFolderViaEmail',
                    type: 'POST',
                    datatype: 'json',
                    data: { compid: compid, folderid: -99, email: linkInput.value, foldername: editorUi.editor.filename, isfilesharing: true },
                    error: function (jqXHR, textStatus, errorThrown) {
                        alert(errorThrown);
                        swal('Alert!', 'Unable to share file', 'error');
                    },
                    success: function (result) {

                        if (result.Message.indexOf("success") == -1) {
                            para.style.color = "red";
                        }
                        else {
                            para.style.color = "green";
                        }


                        para.innerText = result.Message;


                        //$('#foldersharemodal').modal('hide');

                    }

                });



            }
            else {
                para.innerText = "Please enter valid email address";
            }
           
        }
    });

    var cancelBtn = mxUtils.button(mxResources.get('cancel'), function () {
        editorUi.hideDialog();
    });
    cancelBtn.className = 'geBtn';

    if (editorUi.editor.cancelFirst) {
        btns.appendChild(cancelBtn);
    }

    var mainBtn = mxUtils.button(mxResources.get('share'), function () {
        debugger;
        var rooturl = rootUrl;
        if (validateEmail(linkInput.value)) {
            para.style.color = "orange";
            para.innerText = "Processing...";
            var compid = localStorage.getItem("companyid");
            $.ajax({
                url:  '../Graph/ShareFolderViaEmail',
                type: 'POST',
                datatype: 'json',
                data: { compid: compid, folderid: -99, email: linkInput.value, foldername: editorUi.editor.filename, isfilesharing: true },
                error: function (jqXHR, textStatus, errorThrown) {
                    alert(errorThrown);
                    swal('Alert!', 'Unable to share file', 'error');
                },
                success: function (result) {

                    if (result.Message.indexOf("success") == -1) {
                        para.style.color = "red";
                    }
                    else {
                        para.style.color = "green";
                    }


                    para.innerText = result.Message;


                    //$('#foldersharemodal').modal('hide');

                }

            });



        }
        else {
            para.innerText = "Please enter valid email address";
        }
        //editorUi.hideDialog();
        //fn(linkInput.value);
    });
    mainBtn.className = 'geBtn gePrimaryBtn';
    btns.appendChild(mainBtn);

    if (!editorUi.editor.cancelFirst) {
        btns.appendChild(cancelBtn);
    }

    div.appendChild(btns);

    this.container = div;
    //var iframe = document.createElement('iframe');
    //iframe.style.backgroundColor = 'transparent';
    //iframe.allowTransparency = 'true';
    //iframe.style.borderStyle = 'none';
    //iframe.style.borderWidth = '0px';
    //iframe.style.overflow = 'hidden';
    //iframe.frameBorder = '0';



    //iframe.setAttribute('width', '100%');
    //iframe.setAttribute('height', '100%');
    //iframe.setAttribute('src', '../Graph/ShareDiagram?fileName=' + editorUi.editor.filename);










    //this.container = iframe;







};

var DiagramShapesDialog = function (editorUi) {


    var editor = editorUi;
    var entries = editor.sidebar.entries;
    var div = document.createElement('div');
    var newEntries = [];
    var expanded = true;
    var isLocalStorage = false;
    debugger;
    // Adds custom sections first
    if (editorUi.sidebar.customEntries != null) {
        for (var i = 0; i < editorUi.sidebar.customEntries.length; i++) {
            var section = editorUi.sidebar.customEntries[i];
            var tmp = { title: editorUi.getResource(section.title), entries: [] };

            for (var j = 0; j < section.entries.length; j++) {
                var entry = section.entries[j];
                tmp.entries.push({
                    id: entry.id, title:
                        editorUi.getResource(entry.title),
                    desc: editorUi.getResource(entry.desc),
                    image: entry.preview
                });
            }

            newEntries.push(tmp);
        }
    }

    // Adds built-in sections and filter entries
    for (var i = 0; i < entries.length; i++) {
        if (editorUi.sidebar.enabledLibraries == null) {
            newEntries.push(entries[i]);
        }
        else {
            var tmp = { title: entries[i].title, entries: [] };

            for (var j = 0; j < entries[i].entries.length; j++) {
                if (mxUtils.indexOf(editorUi.sidebar.enabledLibraries,
                    entries[i].entries[j].id) >= 0) {
                    tmp.entries.push(entries[i].entries[j]);
                }
            }

            if (tmp.entries.length > 0) {
                newEntries.push(tmp);
            }
        }
    }

    entries = newEntries;
    this.container = div;


    if (expanded) {
        var addEntries = mxUtils.bind(this, function (e) {
            for (var i = 0; i < e.length; i++) {
                (function (section) {
                    var title = listEntry.cloneNode(false);
                    title.style.fontWeight = 'bold';
                    title.style.backgroundColor = Editor.isDarkMode() ? '#505759' : '#e5e5e5';
                    title.style.padding = '6px 0px 6px 20px';
                    mxUtils.write(title, section.title);
                    list.appendChild(title);

                    for (var j = 0; j < section.entries.length; j++) {
                        (function (entry) {
                            var option = listEntry.cloneNode(false);
                            option.style.cursor = 'pointer';
                            option.style.padding = '4px 0px 4px 20px';
                            option.style.whiteSpace = 'nowrap';
                            option.style.overflow = 'hidden';
                            option.style.textOverflow = 'ellipsis';
                            option.setAttribute('title', entry.title + ' (' + entry.id + ')');

                            var checkbox = document.createElement('input');
                            checkbox.setAttribute('type', 'checkbox');
                            checkbox.checked = editorUi.sidebar.isEntryVisible(entry.id);
                            checkbox.defaultChecked = checkbox.checked;
                            option.appendChild(checkbox);
                            mxUtils.write(option, ' ' + entry.title);

                            list.appendChild(option);

                            var itemClicked = function (evt) {
                                if (evt == null || mxEvent.getSource(evt).nodeName != 'INPUT') {
                                    preview.style.textAlign = 'center';
                                    preview.style.padding = '0px';
                                    preview.style.color = '';
                                    preview.innerText = '';

                                    if (entry.desc != null) {
                                        var pre = document.createElement('pre');
                                        pre.style.boxSizing = 'border-box';
                                        pre.style.fontFamily = 'inherit';
                                        pre.style.margin = '20px';
                                        pre.style.right = '0px';
                                        pre.style.textAlign = 'left';
                                        mxUtils.write(pre, entry.desc);
                                        preview.appendChild(pre);
                                    }

                                    if (entry.imageCallback != null) {
                                        entry.imageCallback(preview);
                                    }
                                    else if (entry.image != null) {
                                        preview.innerHTML += '<img border="0" src="' + entry.image + '"/>';
                                    }
                                    else if (entry.desc == null) {
                                        preview.style.padding = '20px';
                                        preview.style.color = 'rgb(179, 179, 179)';
                                        mxUtils.write(preview, mxResources.get('noPreview'));
                                    }

                                    if (currentListItem != null) {
                                        currentListItem.style.backgroundColor = '';
                                    }

                                    currentListItem = option;
                                    currentListItem.style.backgroundColor = Editor.isDarkMode() ? '#000000' : '#ebf2f9';

                                    if (evt != null) {
                                        mxEvent.consume(evt);
                                    }
                                }
                            };

                            mxEvent.addListener(option, 'click', itemClicked);
                            mxEvent.addListener(option, 'dblclick', function (evt) {
                                checkbox.checked = !checkbox.checked;
                                mxEvent.consume(evt);
                            });

                            applyFunctions.push(function () {

                                return (checkbox.checked) ? entry.id : null;
                            });

                            // Selects first entry
                            if (i == 0 && j == 0) {
                                itemClicked();
                            }
                        })(section.entries[j]);
                    }
                })(e[i]);
            }
        });

        var hd = document.createElement('div');
        hd.className = 'geDialogTitle';
        mxUtils.write(hd, mxResources.get('shapes'));
        hd.style.position = 'absolute';
        hd.style.top = '0px';
        hd.style.left = '0px';
        hd.style.lineHeight = '40px';
        hd.style.height = '40px';
        hd.style.right = '0px';

        var list = document.createElement('div');
        var preview = document.createElement('div');

        list.style.position = 'absolute';
        list.style.top = '40px';
        list.style.left = '0px';
        list.style.width = '202px';
        list.style.bottom = '60px';
        list.style.overflow = 'auto';

        preview.style.position = 'absolute';
        preview.style.left = '202px';
        preview.style.right = '0px';
        preview.style.top = '40px';
        preview.style.bottom = '60px';
        preview.style.overflow = 'auto';
        preview.style.borderLeft = '1px solid rgb(211, 211, 211)';
        preview.style.textAlign = 'center';

        var currentListItem = null;
        var applyFunctions = [];

        var listEntry = document.createElement('div');
        listEntry.style.position = 'relative';
        listEntry.style.left = '0px';
        listEntry.style.right = '0px';

        addEntries(entries);
        div.style.padding = '30px';

        div.appendChild(hd);
        div.appendChild(list);
        div.appendChild(preview);

        var buttons = document.createElement('div');
        buttons.className = 'geDialogFooter';
        buttons.style.position = 'absolute';
        buttons.style.paddingRight = '16px';
        buttons.style.color = 'gray';
        buttons.style.left = '0px';
        buttons.style.right = '0px';
        buttons.style.bottom = '0px';
        buttons.style.height = '60px';
        buttons.style.lineHeight = '52px';

        //var labels = document.createElement('input');
        //labels.setAttribute('type', 'checkbox');
        //labels.style.position = 'relative';
        //labels.style.top = '1px';
        //labels.checked = editorUi.sidebar.sidebarTitles;
        //labels.defaultChecked = labels.checked;
        //buttons.appendChild(labels);
        //var span = document.createElement('span');
        //mxUtils.write(span, ' ' + mxResources.get('labels'));
        //span.style.paddingRight = '20px';
        //buttons.appendChild(span);

        //mxEvent.addListener(span, 'click', function (evt) {
        //    labels.checked = !labels.checked;
        //    mxEvent.consume(evt);
        //});
        var cb = document.createElement('input');
        cb.setAttribute('type', 'checkbox');

        if (isLocalStorage || mxClient.IS_CHROMEAPP) {


            var span = document.createElement('span');
            span.style.paddingRight = '20px';
            span.appendChild(cb);
            mxUtils.write(span, ' ' + mxResources.get('rememberThisSetting'));
            cb.style.position = 'relative';
            cb.style.top = '1px';
            cb.checked = true;
            cb.defaultChecked = true;

            mxEvent.addListener(span, 'click', function (evt) {
                if (mxEvent.getSource(evt) != cb) {
                    cb.checked = !cb.checked;
                    mxEvent.consume(evt);
                }
            });

            buttons.appendChild(span);
        }

        var cancelBtn = mxUtils.button(mxResources.get('cancel'), function () {
            editorUi.hideDialog();
        });
        cancelBtn.className = 'geBtn';

        var applyBtn = mxUtils.button(mxResources.get('apply'), function () {
            editorUi.hideDialog();
            var libs = [];

            for (var i = 0; i < applyFunctions.length; i++) {
                var lib = applyFunctions[i].apply(this, arguments);

                if (lib != null) {
                   // AddPalleteToSidebar(editorUi, libs, lib);
                    libs.push(lib);
                    

                }
            }
           

            // Redirects scratchpad and search entries
            if (urlParams['sketch'] == '1' && editorUi.isSettingsEnabled()) {
                var idx = mxUtils.indexOf(libs, '.scratchpad');

                if ((editorUi.scratchpad != null) != (idx >= 0 && libs.splice(idx, 1).length > 0)) {
                    editorUi.toggleScratchpad();
                }

                // Handles search after scratchpad
                idx = mxUtils.indexOf(libs, 'search');
                mxSettings.settings.search = (idx >= 0 && libs.splice(idx, 1).length > 0);
                editorUi.sidebar.showPalette('search', mxSettings.settings.search);

                if (cb.checked) {
                    mxSettings.save();
                }
            }

            editorUi.sidebar.showEntries(libs.join(';'), cb.checked, true);
            //editorUi.setSidebarTitles(labels.checked, cb.checked);
        });
        applyBtn.className = 'geBtn gePrimaryBtn';

        if (editorUi.editor.cancelFirst) {
            buttons.appendChild(cancelBtn);
            buttons.appendChild(applyBtn);
        }
        else {
            buttons.appendChild(applyBtn);
            buttons.appendChild(cancelBtn);
        }

        div.appendChild(buttons);
    }
    else {
        var libFS = document.createElement('table');
        var tbody = document.createElement('tbody');
        div.style.height = '100%';
        div.style.overflow = 'auto';
        var row = document.createElement('tr');
        libFS.style.width = '100%';

        var leftDiv = document.createElement('td');
        var midDiv = document.createElement('td');
        var rightDiv = document.createElement('td');

        var addLibCB = mxUtils.bind(this, function (wrapperDiv, title, key) {
            var libCB = document.createElement('input');
            libCB.type = 'checkbox';
            libFS.appendChild(libCB);

            libCB.checked = editorUi.sidebar.isEntryVisible(key);

            var libSpan = document.createElement('span');
            mxUtils.write(libSpan, title);

            var label = document.createElement('div');
            label.style.display = 'block';
            label.appendChild(libCB);
            label.appendChild(libSpan);

            mxEvent.addListener(libSpan, 'click', function (evt) {
                libCB.checked = !libCB.checked;
                mxEvent.consume(evt);
            });

            wrapperDiv.appendChild(label);

            return function () {
                return (libCB.checked) ? key : null;
            };
        });

        row.appendChild(leftDiv);
        row.appendChild(midDiv);
        row.appendChild(rightDiv);

        tbody.appendChild(row);
        libFS.appendChild(tbody);

        var applyFunctions = [];
        var count = 0;

        // Counts total number of entries
        for (var i = 0; i < entries.length; i++) {
            for (var j = 0; j < entries[i].entries.length; j++) {
                count++;
            }
        }

        // Distributes entries on columns
        var cols = [leftDiv, midDiv, rightDiv];
        var counter = 0;

        for (var i = 0; i < entries.length; i++) {
            (function (section) {
                for (var j = 0; j < section.entries.length; j++) {
                    (function (entry) {
                        var index = Math.floor(counter / (count / 3));
                        applyFunctions.push(addLibCB(cols[index], entry.title, entry.id));
                        counter++;
                    })(section.entries[j]);
                }
            })(entries[i]);
        }

        div.appendChild(libFS);

        var remember = document.createElement('div');
        remember.style.marginTop = '18px';
        remember.style.textAlign = 'center';

        var cb = document.createElement('input');

        if (isLocalStorage) {
            cb.setAttribute('type', 'checkbox');
            cb.checked = true;
            cb.defaultChecked = true;
            remember.appendChild(cb);
            var span = document.createElement('span');
            mxUtils.write(span, ' ' + mxResources.get('rememberThisSetting'));
            remember.appendChild(span);

            mxEvent.addListener(span, 'click', function (evt) {
                cb.checked = !cb.checked;
                mxEvent.consume(evt);
            });
        }

        div.appendChild(remember);

        var cancelBtn = mxUtils.button(mxResources.get('cancel'), function () {
            editorUi.hideDialog();
        });
        cancelBtn.className = 'geBtn';

        var applyBtn = mxUtils.button(mxResources.get('apply'), function () {
            var libs = ['search'];

            for (var i = 0; i < applyFunctions.length; i++) {
                var lib = applyFunctions[i].apply(this, arguments);

                if (lib != null) {
                   // AddPalleteToSidebar(editorUi, libs, lib);
                    libs.push(lib);
                }
            }
            debugger;
            editorUi.sidebar.showEntries((libs.length > 0) ? libs.join(';') : '', cb.checked);
            editorUi.hideDialog();
        });
        applyBtn.className = 'geBtn gePrimaryBtn';

        var buttons = document.createElement('div');
        buttons.style.marginTop = '26px';
        buttons.style.textAlign = 'right';

        if (editorUi.editor.cancelFirst) {
            buttons.appendChild(cancelBtn);
            buttons.appendChild(applyBtn);
        }
        else {
            buttons.appendChild(applyBtn);
            buttons.appendChild(cancelBtn);
        }

        div.appendChild(buttons);
    }

    this.container = div;



};

function AddPalleteToSidebar(editorUi,libs,lib) {
   

    if (editorUi.sidebar.palettes[lib] == null) {
      
        switch (lib) {
            case 'active_directory':
                loadScript('/graph/js/AdditionalSidebars/Sidebar-ActiveDirectory.js', () => {


                    editorUi.sidebar.addActiveDirectoryPalette();
                    libs.push(lib);

                    // Do something with the script.
                }, () => {
                    console.error("active_directory");
                    // Handle error.
                });
                break;
            case 'android':
                loadScript('/graph/js/AdditionalSidebars/Sidebar-Android.js', () => {


                    editorUi.sidebar.addAndroidPalette();
                    libs.push(lib);

                    // Do something with the script.
                }, () => {
                    console.error("active_directory");
                    // Handle error.
                });
                break;
            case 'flowchart':
                loadScript('/graph/js/AdditionalSidebars/Sidebar-Flowchart.js', () => {
                    editorUi.sidebar.addFlowchartPalette();
                  
                }, () => {
                    console.error("flowchart");
                  
                });
                break;
            case 'atlassian':
                loadScript('/graph/js/AdditionalSidebars/Sidebar-Atlassian.js', () => {
                    editorUi.sidebar.addAtlassianPalette();
                  
                    // Do something with the script.
                }, () => {
                    console.error("atlassian");
                    // Handle error.
                });
                break;
            case 'bootstrap':
                loadScript('/graph/js/AdditionalSidebars/Sidebar-Bootstrap.js', () => {
                    editorUi.sidebar.addBootstrapPalette();
                    
                    // Do something with the script.
                }, () => {
                    console.error("atlassian");
                    // Handle error.
                });
                break;
            default:
                break;
            // code block
        }

            
        }
        else {
            libs.push(lib);
        }
   
}

function OpenSelectedShapes(ShapeCategory, divRight, editor) {

    divRight.innerHTML = "";
    var result = editor.sidebar.palettes[ShapeCategory.toLowerCase()];

    if (result != null) {


        var sidebar = result[1];

        if (sidebar != null) {

            if (sidebar.children != null) {

                var svgs = sidebar.children[0].children;

                for (var i = 0; i < svgs.length; i++) {

                    var img = document.createElement('div');
                    debugger;


                    img.innerHTML = svgs[i].innerHTML;

                    divRight.appendChild(img);



                }

            }
        }


    }



}
/**
 * Constructs a new color dialog.
 */
var ColorDialog = function (editorUi, color, apply, cancelFn) {
    this.editorUi = editorUi;

    var input = document.createElement('input');
    input.style.marginBottom = '10px';

    // Required for picker to render in IE
    if (mxClient.IS_IE) {
        input.style.marginTop = '10px';
        document.body.appendChild(input);
    }

    var applyFunction = (apply != null) ? apply : this.createApplyFunction();

    function doApply() {
        var color = input.value;

        // Blocks any non-alphabetic chars in colors
        if (/(^#?[a-zA-Z0-9]*$)/.test(color)) {
            if (color != 'none' && color.charAt(0) != '#') {
                color = '#' + color;
            }

            ColorDialog.addRecentColor((color != 'none') ? color.substring(1) : color, 12);
            applyFunction(color);
            editorUi.hideDialog();
        }
        else {
            editorUi.handleError({ message: mxResources.get('invalidInput') });
        }
    };

    this.init = function () {
        if (!mxClient.IS_TOUCH) {
            input.focus();
        }
    };

    var picker = new mxJSColor.color(input);
    picker.pickerOnfocus = false;
    picker.showPicker();

    var div = document.createElement('div');
    mxJSColor.picker.box.style.position = 'relative';
    mxJSColor.picker.box.style.width = '230px';
    mxJSColor.picker.box.style.height = '100px';
    mxJSColor.picker.box.style.paddingBottom = '10px';
    div.appendChild(mxJSColor.picker.box);

    var center = document.createElement('center');

    function createRecentColorTable() {
        var table = addPresets((ColorDialog.recentColors.length == 0) ? ['FFFFFF'] :
            ColorDialog.recentColors, 11, 'FFFFFF', true);
        table.style.marginBottom = '8px';

        return table;
    };

    var addPresets = mxUtils.bind(this, function (presets, rowLength, defaultColor, addResetOption) {
        rowLength = (rowLength != null) ? rowLength : 12;
        var table = document.createElement('table');
        table.style.borderCollapse = 'collapse';
        table.setAttribute('cellspacing', '0');
        table.style.marginBottom = '20px';
        table.style.cellSpacing = '0px';
        table.style.marginLeft = '1px';
        var tbody = document.createElement('tbody');
        table.appendChild(tbody);

        var rows = presets.length / rowLength;

        for (var row = 0; row < rows; row++) {
            var tr = document.createElement('tr');

            for (var i = 0; i < rowLength; i++) {
                (mxUtils.bind(this, function (clr) {
                    var td = document.createElement('td');
                    td.style.border = '0px solid black';
                    td.style.padding = '0px';
                    td.style.width = '16px';
                    td.style.height = '16px';

                    if (clr == null) {
                        clr = defaultColor;
                    }

                    if (clr != null) {
                        td.style.borderWidth = '1px';

                        if (clr == 'none') {
                            td.style.background = 'url(\'' + Dialog.prototype.noColorImage + '\')';
                        }
                        else {
                            td.style.backgroundColor = '#' + clr;
                        }

                        var name = this.colorNames[clr.toUpperCase()];

                        if (name != null) {
                            td.setAttribute('title', name);
                        }
                    }

                    tr.appendChild(td);

                    if (clr != null) {
                        td.style.cursor = 'pointer';

                        mxEvent.addListener(td, 'click', function () {
                            if (clr == 'none') {
                                picker.fromString('ffffff');
                                input.value = 'none';
                            }
                            else {
                                picker.fromString(clr);
                            }
                        });

                        mxEvent.addListener(td, 'dblclick', doApply);
                    }
                }))(presets[row * rowLength + i]);
            }

            tbody.appendChild(tr);
        }

        if (addResetOption) {
            var td = document.createElement('td');
            td.setAttribute('title', mxResources.get('reset'));
            td.style.border = '1px solid black';
            td.style.padding = '0px';
            td.style.width = '16px';
            td.style.height = '16px';
            td.style.backgroundImage = 'url(\'' + Dialog.prototype.closeImage + '\')';
            td.style.backgroundPosition = 'center center';
            td.style.backgroundRepeat = 'no-repeat';
            td.style.cursor = 'pointer';

            tr.appendChild(td);

            mxEvent.addListener(td, 'click', function () {
                ColorDialog.resetRecentColors();
                table.parentNode.replaceChild(createRecentColorTable(), table);
            });
        }

        center.appendChild(table);

        return table;
    });

    div.appendChild(input);

    if (!mxClient.IS_IE && !mxClient.IS_IE11) {
        input.style.width = '182px';

        var clrInput = document.createElement('input');
        clrInput.setAttribute('type', 'color');
        clrInput.style.visibility = 'hidden';
        clrInput.style.width = '0px';
        clrInput.style.height = '0px';
        clrInput.style.border = 'none';
        clrInput.style.marginLeft = '2px';
        div.style.whiteSpace = 'nowrap';
        div.appendChild(clrInput);

        div.appendChild(mxUtils.button('...', function () {
            // LATER: Check if clrInput is expanded
            if (document.activeElement == clrInput) {
                input.focus();
            }
            else {
                clrInput.value = '#' + input.value;
                clrInput.click();
            }
        }));

        mxEvent.addListener(clrInput, 'input', function () {
            picker.fromString(clrInput.value.substring(1));
        });
    }
    else {
        input.style.width = '216px';
    }

    mxUtils.br(div);

    // Adds recent colors
    createRecentColorTable();

    // Adds presets
    var table = addPresets(this.presetColors);
    table.style.marginBottom = '8px';
    table = addPresets(this.defaultColors);
    table.style.marginBottom = '16px';

    div.appendChild(center);

    var buttons = document.createElement('div');
    buttons.style.textAlign = 'right';
    buttons.style.whiteSpace = 'nowrap';

    var cancelBtn = mxUtils.button(mxResources.get('cancel'), function () {
        editorUi.hideDialog();

        if (cancelFn != null) {
            cancelFn();
        }
    });
    cancelBtn.className = 'geBtn';

    if (editorUi.editor.cancelFirst) {
        buttons.appendChild(cancelBtn);
    }

    var applyBtn = mxUtils.button(mxResources.get('apply'), doApply);
    applyBtn.className = 'geBtn gePrimaryBtn';
    buttons.appendChild(applyBtn);

    if (!editorUi.editor.cancelFirst) {
        buttons.appendChild(cancelBtn);
    }

    if (color != null) {
        if (color == 'none') {
            picker.fromString('ffffff');
            input.value = 'none';
        }
        else {
            picker.fromString(color);
        }
    }

    div.appendChild(buttons);
    this.picker = picker;
    this.colorInput = input;

    // LATER: Only fires if input if focused, should always
    // fire if this dialog is showing.
    mxEvent.addListener(div, 'keydown', function (e) {
        if (e.keyCode == 27) {
            editorUi.hideDialog();

            if (cancelFn != null) {
                cancelFn();
            }

            mxEvent.consume(e);
        }
    });

    this.container = div;
};

/**
 * Creates function to apply value
 */
ColorDialog.prototype.presetColors = ['E6D0DE', 'CDA2BE', 'B5739D', 'E1D5E7', 'C3ABD0', 'A680B8', 'D4E1F5', 'A9C4EB', '7EA6E0', 'D5E8D4', '9AC7BF', '67AB9F', 'D5E8D4', 'B9E0A5', '97D077', 'FFF2CC', 'FFE599', 'FFD966', 'FFF4C3', 'FFCE9F', 'FFB570', 'F8CECC', 'F19C99', 'EA6B66'];

/**
 * Creates function to apply value
 */
ColorDialog.prototype.colorNames = {};

/**
 * Creates function to apply value
 */
ColorDialog.prototype.defaultColors = ['none', 'FFFFFF', 'E6E6E6', 'CCCCCC', 'B3B3B3', '999999', '808080', '666666', '4D4D4D', '333333', '1A1A1A', '000000', 'FFCCCC', 'FFE6CC', 'FFFFCC', 'E6FFCC', 'CCFFCC', 'CCFFE6', 'CCFFFF', 'CCE5FF', 'CCCCFF', 'E5CCFF', 'FFCCFF', 'FFCCE6',
    'FF9999', 'FFCC99', 'FFFF99', 'CCFF99', '99FF99', '99FFCC', '99FFFF', '99CCFF', '9999FF', 'CC99FF', 'FF99FF', 'FF99CC', 'FF6666', 'FFB366', 'FFFF66', 'B3FF66', '66FF66', '66FFB3', '66FFFF', '66B2FF', '6666FF', 'B266FF', 'FF66FF', 'FF66B3', 'FF3333', 'FF9933', 'FFFF33',
    '99FF33', '33FF33', '33FF99', '33FFFF', '3399FF', '3333FF', '9933FF', 'FF33FF', 'FF3399', 'FF0000', 'FF8000', 'FFFF00', '80FF00', '00FF00', '00FF80', '00FFFF', '007FFF', '0000FF', '7F00FF', 'FF00FF', 'FF0080', 'CC0000', 'CC6600', 'CCCC00', '66CC00', '00CC00', '00CC66',
    '00CCCC', '0066CC', '0000CC', '6600CC', 'CC00CC', 'CC0066', '990000', '994C00', '999900', '4D9900', '009900', '00994D', '009999', '004C99', '000099', '4C0099', '990099', '99004D', '660000', '663300', '666600', '336600', '006600', '006633', '006666', '003366', '000066',
    '330066', '660066', '660033', '330000', '331A00', '333300', '1A3300', '003300', '00331A', '003333', '001933', '000033', '190033', '330033', '33001A'];

/**
 * Creates function to apply value
 */
ColorDialog.prototype.createApplyFunction = function () {
    return mxUtils.bind(this, function (color) {
        var graph = this.editorUi.editor.graph;

        graph.getModel().beginUpdate();
        try {
            graph.setCellStyles(this.currentColorKey, color);
            this.editorUi.fireEvent(new mxEventObject('styleChanged', 'keys', [this.currentColorKey],
                'values', [color], 'cells', graph.getSelectionCells()));
        }
        finally {
            graph.getModel().endUpdate();
        }
    });
};

/**
 * 
 */
ColorDialog.recentColors = [];

/**
 * Adds recent color for later use.
 */
ColorDialog.addRecentColor = function (color, max) {
    if (color != null) {
        mxUtils.remove(color, ColorDialog.recentColors);
        ColorDialog.recentColors.splice(0, 0, color);

        if (ColorDialog.recentColors.length >= max) {
            ColorDialog.recentColors.pop();
        }
    }
};

/**
 * Adds recent color for later use.
 */
ColorDialog.resetRecentColors = function () {
    ColorDialog.recentColors = [];
};

/**
 * Constructs a new about dialog.
 */
var AboutDialog = function (editorUi) {
    var div = document.createElement('div');
    div.setAttribute('align', 'center');
    var h3 = document.createElement('h3');
    mxUtils.write(h3, mxResources.get('about') + ' GraphEditor');
    div.appendChild(h3);
    var img = document.createElement('img');
    img.style.border = '0px';
    img.setAttribute('width', '176');
    img.setAttribute('width', '151');
    img.setAttribute('src', IMAGE_PATH + '/logo.png');
    div.appendChild(img);
    mxUtils.br(div);
    mxUtils.write(div, 'Powered by mxGraph ' + mxClient.VERSION);
    mxUtils.br(div);
    var link = document.createElement('a');
    link.setAttribute('href', 'http://www.jgraph.com/');
    link.setAttribute('target', '_blank');
    mxUtils.write(link, 'www.jgraph.com');
    div.appendChild(link);
    mxUtils.br(div);
    mxUtils.br(div);
    var closeBtn = mxUtils.button(mxResources.get('close'), function () {
        editorUi.hideDialog();
    });
    closeBtn.className = 'geBtn gePrimaryBtn';
    div.appendChild(closeBtn);

    this.container = div;
};

/**
 * Constructs a new textarea dialog.
 */
var TextareaDialog = function (editorUi, title, url, fn, cancelFn, cancelTitle, w, h,
    addButtons, noHide, noWrap, applyTitle, helpLink, customButtons, header) {
    w = (w != null) ? w : 300;
    h = (h != null) ? h : 120;
    noHide = (noHide != null) ? noHide : false;

    var div = document.createElement('div');
    div.style.position = 'absolute';
    div.style.top = '20px';
    div.style.bottom = '20px';
    div.style.left = '20px';
    div.style.right = '20px';

    var top = document.createElement('div');

    top.style.position = 'absolute';
    top.style.left = '0px';
    top.style.right = '0px';

    var main = top.cloneNode(false);
    var buttons = top.cloneNode(false);

    top.style.top = '0px';
    top.style.height = '20px';
    main.style.top = '20px';
    main.style.bottom = '64px';
    buttons.style.bottom = '0px';
    buttons.style.height = '60px';
    buttons.style.textAlign = 'center';

    mxUtils.write(top, title);

    div.appendChild(top);
    div.appendChild(main);
    div.appendChild(buttons);

    if (header != null) {
        top.appendChild(header);
    }

    var nameInput = document.createElement('textarea');

    if (noWrap) {
        nameInput.setAttribute('wrap', 'off');
    }

    nameInput.setAttribute('spellcheck', 'false');
    nameInput.setAttribute('autocorrect', 'off');
    nameInput.setAttribute('autocomplete', 'off');
    nameInput.setAttribute('autocapitalize', 'off');

    mxUtils.write(nameInput, url || '');
    nameInput.style.resize = 'none';
    nameInput.style.outline = 'none';
    nameInput.style.position = 'absolute';
    nameInput.style.boxSizing = 'border-box';
    nameInput.style.top = '0px';
    nameInput.style.left = '0px';
    nameInput.style.height = '100%';
    nameInput.style.width = '100%';

    this.textarea = nameInput;

    this.init = function () {
        nameInput.focus();
        nameInput.scrollTop = 0;
    };

    main.appendChild(nameInput);

    if (helpLink != null) {
        var helpBtn = mxUtils.button(mxResources.get('help'), function () {
            editorUi.editor.graph.openLink(helpLink);
        });
        helpBtn.className = 'geBtn';

        buttons.appendChild(helpBtn);
    }

    if (customButtons != null) {
        for (var i = 0; i < customButtons.length; i++) {
            (function (label, fn, title) {
                var customBtn = mxUtils.button(label, function (e) {
                    fn(e, nameInput);
                });

                if (title != null) {
                    customBtn.setAttribute('title', title);
                }

                customBtn.className = 'geBtn';

                buttons.appendChild(customBtn);
            })(customButtons[i][0], customButtons[i][1], customButtons[i][2]);
        }
    }

    var cancelBtn = mxUtils.button(cancelTitle || mxResources.get('cancel'), function () {
        editorUi.hideDialog();

        if (cancelFn != null) {
            cancelFn();
        }
    });

    cancelBtn.setAttribute('title', 'Escape');
    cancelBtn.className = 'geBtn';

    if (editorUi.editor.cancelFirst) {
        buttons.appendChild(cancelBtn);
    }

    if (addButtons != null) {
        addButtons(buttons, nameInput);
    }

    if (fn != null) {
        var genericBtn = mxUtils.button(applyTitle || mxResources.get('apply'), function () {
            if (!noHide) {
                editorUi.hideDialog();
            }

            fn(nameInput.value);
        });

        genericBtn.setAttribute('title', 'Ctrl+Enter');
        genericBtn.className = 'geBtn gePrimaryBtn';
        buttons.appendChild(genericBtn);

        mxEvent.addListener(nameInput, 'keypress', function (e) {
            if (e.keyCode == 13 && mxEvent.isControlDown(e)) {
                genericBtn.click();
            }
        });
    }

    if (!editorUi.editor.cancelFirst) {
        buttons.appendChild(cancelBtn);
    }

    this.container = div;
};

/**
 * Constructs a new edit file dialog.
 */
var EditDiagramDialog = function (editorUi) {
    var div = document.createElement('div');
    div.style.textAlign = 'right';
    var textarea = document.createElement('textarea');
    textarea.setAttribute('wrap', 'off');
    textarea.setAttribute('spellcheck', 'false');
    textarea.setAttribute('autocorrect', 'off');
    textarea.setAttribute('autocomplete', 'off');
    textarea.setAttribute('autocapitalize', 'off');
    textarea.style.overflow = 'auto';
    textarea.style.resize = 'none';
    textarea.style.width = '600px';
    textarea.style.height = '360px';
    textarea.style.marginBottom = '16px';

    textarea.value = mxUtils.getPrettyXml(editorUi.editor.getGraphXml());
    div.appendChild(textarea);

    this.init = function () {
        textarea.focus();
    };

    // Enables dropping files
    if (Graph.fileSupport) {
        function handleDrop(evt) {
            evt.stopPropagation();
            evt.preventDefault();

            if (evt.dataTransfer.files.length > 0) {
                var file = evt.dataTransfer.files[0];
                var reader = new FileReader();

                reader.onload = function (e) {
                    textarea.value = e.target.result;
                };

                reader.readAsText(file);
            }
            else {
                textarea.value = editorUi.extractGraphModelFromEvent(evt);
            }
        };

        function handleDragOver(evt) {
            evt.stopPropagation();
            evt.preventDefault();
        };

        // Setup the dnd listeners.
        textarea.addEventListener('dragover', handleDragOver, false);
        textarea.addEventListener('drop', handleDrop, false);
    }

    var cancelBtn = mxUtils.button(mxResources.get('cancel'), function () {
        editorUi.hideDialog();
    });
    cancelBtn.className = 'geBtn';

    if (editorUi.editor.cancelFirst) {
        div.appendChild(cancelBtn);
    }

    var select = document.createElement('select');
    select.style.width = '180px';
    select.className = 'geBtn';

    if (editorUi.editor.graph.isEnabled()) {
        var replaceOption = document.createElement('option');
        replaceOption.setAttribute('value', 'replace');
        mxUtils.write(replaceOption, mxResources.get('replaceExistingDrawing'));
        select.appendChild(replaceOption);
    }

    var newOption = document.createElement('option');
    newOption.setAttribute('value', 'new');
    mxUtils.write(newOption, mxResources.get('openInNewWindow'));

    if (EditDiagramDialog.showNewWindowOption) {
        select.appendChild(newOption);
    }

    if (editorUi.editor.graph.isEnabled()) {
        var importOption = document.createElement('option');
        importOption.setAttribute('value', 'import');
        mxUtils.write(importOption, mxResources.get('addToExistingDrawing'));
        select.appendChild(importOption);
    }

    div.appendChild(select);

    var okBtn = mxUtils.button(mxResources.get('ok'), function () {
        // Removes all illegal control characters before parsing
        var data = Graph.zapGremlins(mxUtils.trim(textarea.value));
        var error = null;

        if (select.value == 'new') {
            editorUi.hideDialog();
            editorUi.editor.editAsNew(data);
        }
        else if (select.value == 'replace') {
            editorUi.editor.graph.model.beginUpdate();
            try {
                editorUi.editor.setGraphXml(mxUtils.parseXml(data).documentElement);
                // LATER: Why is hideDialog between begin-/endUpdate faster?
                editorUi.hideDialog();
            }
            catch (e) {
                error = e;
            }
            finally {
                editorUi.editor.graph.model.endUpdate();
            }
        }
        else if (select.value == 'import') {
            editorUi.editor.graph.model.beginUpdate();
            try {
                var doc = mxUtils.parseXml(data);
                var model = new mxGraphModel();
                var codec = new mxCodec(doc);
                codec.decode(doc.documentElement, model);

                var children = model.getChildren(model.getChildAt(model.getRoot(), 0));
                editorUi.editor.graph.setSelectionCells(editorUi.editor.graph.importCells(children));

                // LATER: Why is hideDialog between begin-/endUpdate faster?
                editorUi.hideDialog();
            }
            catch (e) {
                error = e;
            }
            finally {
                editorUi.editor.graph.model.endUpdate();
            }
        }

        if (error != null) {
            mxUtils.alert(error.message);
        }
    });
    okBtn.className = 'geBtn gePrimaryBtn';
    div.appendChild(okBtn);

    if (!editorUi.editor.cancelFirst) {
        div.appendChild(cancelBtn);
    }

    this.container = div;
};

/**
 * 
 */
EditDiagramDialog.showNewWindowOption = true;

/**
 * Constructs a new export dialog.
 */
var ExportDialog = function (editorUi) {
    var graph = editorUi.editor.graph;
    var bounds = graph.getGraphBounds();
    var scale = graph.view.scale;

    var width = Math.ceil(bounds.width / scale);
    var height = Math.ceil(bounds.height / scale);

    var row, td;

    var table = document.createElement('table');
    var tbody = document.createElement('tbody');
    table.setAttribute('cellpadding', (mxClient.IS_SF) ? '0' : '2');

    row = document.createElement('tr');

    td = document.createElement('td');
    td.style.fontSize = '10pt';
    td.style.width = '100px';
    mxUtils.write(td, mxResources.get('filename') + ':');

    row.appendChild(td);

    var nameInput = document.createElement('input');
    nameInput.setAttribute('value', editorUi.editor.getOrCreateFilename());
    nameInput.style.width = '180px';

    td = document.createElement('td');
    td.appendChild(nameInput);
    row.appendChild(td);

    tbody.appendChild(row);

    row = document.createElement('tr');

    td = document.createElement('td');
    td.style.fontSize = '10pt';
    mxUtils.write(td, mxResources.get('format') + ':');

    row.appendChild(td);

    var imageFormatSelect = document.createElement('select');
    imageFormatSelect.style.width = '180px';

    var pngOption = document.createElement('option');
    pngOption.setAttribute('value', 'png');
    mxUtils.write(pngOption, mxResources.get('formatPng'));
    imageFormatSelect.appendChild(pngOption);

    var gifOption = document.createElement('option');

    if (ExportDialog.showGifOption) {
        gifOption.setAttribute('value', 'gif');
        mxUtils.write(gifOption, mxResources.get('formatGif'));
        imageFormatSelect.appendChild(gifOption);
    }

    var jpgOption = document.createElement('option');
    jpgOption.setAttribute('value', 'jpg');
    mxUtils.write(jpgOption, mxResources.get('formatJpg'));
    imageFormatSelect.appendChild(jpgOption);

    var pdfOption = document.createElement('option');
    pdfOption.setAttribute('value', 'pdf');
    mxUtils.write(pdfOption, mxResources.get('formatPdf'));
    imageFormatSelect.appendChild(pdfOption);

    var svgOption = document.createElement('option');
    svgOption.setAttribute('value', 'svg');
    mxUtils.write(svgOption, mxResources.get('formatSvg'));
    imageFormatSelect.appendChild(svgOption);

    if (ExportDialog.showXmlOption) {
        var xmlOption = document.createElement('option');
        xmlOption.setAttribute('value', 'xml');
        mxUtils.write(xmlOption, mxResources.get('formatXml'));
        imageFormatSelect.appendChild(xmlOption);
    }

    td = document.createElement('td');
    td.appendChild(imageFormatSelect);
    row.appendChild(td);

    tbody.appendChild(row);

    row = document.createElement('tr');

    td = document.createElement('td');
    td.style.fontSize = '10pt';
    mxUtils.write(td, mxResources.get('zoom') + ' (%):');

    row.appendChild(td);

    var zoomInput = document.createElement('input');
    zoomInput.setAttribute('type', 'number');
    zoomInput.setAttribute('value', '100');
    zoomInput.style.width = '180px';

    td = document.createElement('td');
    td.appendChild(zoomInput);
    row.appendChild(td);

    tbody.appendChild(row);

    row = document.createElement('tr');

    td = document.createElement('td');
    td.style.fontSize = '10pt';
    mxUtils.write(td, mxResources.get('width') + ':');

    row.appendChild(td);

    var widthInput = document.createElement('input');
    widthInput.setAttribute('value', width);
    widthInput.style.width = '180px';

    td = document.createElement('td');
    td.appendChild(widthInput);
    row.appendChild(td);

    tbody.appendChild(row);

    row = document.createElement('tr');

    td = document.createElement('td');
    td.style.fontSize = '10pt';
    mxUtils.write(td, mxResources.get('height') + ':');

    row.appendChild(td);

    var heightInput = document.createElement('input');
    heightInput.setAttribute('value', height);
    heightInput.style.width = '180px';

    td = document.createElement('td');
    td.appendChild(heightInput);
    row.appendChild(td);

    tbody.appendChild(row);

    row = document.createElement('tr');

    td = document.createElement('td');
    td.style.fontSize = '10pt';
    mxUtils.write(td, mxResources.get('dpi') + ':');

    row.appendChild(td);

    var dpiSelect = document.createElement('select');
    dpiSelect.style.width = '180px';

    var dpi100Option = document.createElement('option');
    dpi100Option.setAttribute('value', '100');
    mxUtils.write(dpi100Option, '100dpi');
    dpiSelect.appendChild(dpi100Option);

    var dpi200Option = document.createElement('option');
    dpi200Option.setAttribute('value', '200');
    mxUtils.write(dpi200Option, '200dpi');
    dpiSelect.appendChild(dpi200Option);

    var dpi300Option = document.createElement('option');
    dpi300Option.setAttribute('value', '300');
    mxUtils.write(dpi300Option, '300dpi');
    dpiSelect.appendChild(dpi300Option);

    var dpi400Option = document.createElement('option');
    dpi400Option.setAttribute('value', '400');
    mxUtils.write(dpi400Option, '400dpi');
    dpiSelect.appendChild(dpi400Option);

    var dpiCustOption = document.createElement('option');
    dpiCustOption.setAttribute('value', 'custom');
    mxUtils.write(dpiCustOption, mxResources.get('custom'));
    dpiSelect.appendChild(dpiCustOption);

    var customDpi = document.createElement('input');
    customDpi.style.width = '180px';
    customDpi.style.display = 'none';
    customDpi.setAttribute('value', '100');
    customDpi.setAttribute('type', 'number');
    customDpi.setAttribute('min', '50');
    customDpi.setAttribute('step', '50');

    var zoomUserChanged = false;

    mxEvent.addListener(dpiSelect, 'change', function () {
        if (this.value == 'custom') {
            this.style.display = 'none';
            customDpi.style.display = '';
            customDpi.focus();
        }
        else {
            customDpi.value = this.value;

            if (!zoomUserChanged) {
                zoomInput.value = this.value;
            }
        }
    });

    mxEvent.addListener(customDpi, 'change', function () {
        var dpi = parseInt(customDpi.value);

        if (isNaN(dpi) || dpi <= 0) {
            customDpi.style.backgroundColor = 'red';
        }
        else {
            customDpi.style.backgroundColor = '';

            if (!zoomUserChanged) {
                zoomInput.value = dpi;
            }
        }
    });

    td = document.createElement('td');
    td.appendChild(dpiSelect);
    td.appendChild(customDpi);
    row.appendChild(td);

    tbody.appendChild(row);

    row = document.createElement('tr');

    td = document.createElement('td');
    td.style.fontSize = '10pt';
    mxUtils.write(td, mxResources.get('background') + ':');

    row.appendChild(td);

    var transparentCheckbox = document.createElement('input');
    transparentCheckbox.setAttribute('type', 'checkbox');
    transparentCheckbox.checked = graph.background == null || graph.background == mxConstants.NONE;

    td = document.createElement('td');
    td.appendChild(transparentCheckbox);
    mxUtils.write(td, mxResources.get('transparent'));

    row.appendChild(td);

    tbody.appendChild(row);

    row = document.createElement('tr');

    td = document.createElement('td');
    td.style.fontSize = '10pt';
    mxUtils.write(td, mxResources.get('grid') + ':');

    row.appendChild(td);

    var gridCheckbox = document.createElement('input');
    gridCheckbox.setAttribute('type', 'checkbox');
    gridCheckbox.checked = false;

    td = document.createElement('td');
    td.appendChild(gridCheckbox);

    row.appendChild(td);

    tbody.appendChild(row);

    row = document.createElement('tr');

    td = document.createElement('td');
    td.style.fontSize = '10pt';
    mxUtils.write(td, mxResources.get('borderWidth') + ':');

    row.appendChild(td);

    var borderInput = document.createElement('input');
    borderInput.setAttribute('type', 'number');
    borderInput.setAttribute('value', ExportDialog.lastBorderValue);
    borderInput.style.width = '180px';

    td = document.createElement('td');
    td.appendChild(borderInput);
    row.appendChild(td);

    tbody.appendChild(row);
    table.appendChild(tbody);

    // Handles changes in the export format
    function formatChanged() {
        var name = nameInput.value;
        var dot = name.lastIndexOf('.');

        if (dot > 0) {
            nameInput.value = name.substring(0, dot + 1) + imageFormatSelect.value;
        }
        else {
            nameInput.value = name + '.' + imageFormatSelect.value;
        }

        if (imageFormatSelect.value === 'xml') {
            zoomInput.setAttribute('disabled', 'true');
            widthInput.setAttribute('disabled', 'true');
            heightInput.setAttribute('disabled', 'true');
            borderInput.setAttribute('disabled', 'true');
        }
        else {
            zoomInput.removeAttribute('disabled');
            widthInput.removeAttribute('disabled');
            heightInput.removeAttribute('disabled');
            borderInput.removeAttribute('disabled');
        }

        if (imageFormatSelect.value === 'png' || imageFormatSelect.value === 'svg' || imageFormatSelect.value === 'pdf') {
            transparentCheckbox.removeAttribute('disabled');
        }
        else {
            transparentCheckbox.setAttribute('disabled', 'disabled');
        }

        if (imageFormatSelect.value === 'png' || imageFormatSelect.value === 'jpg' || imageFormatSelect.value === 'pdf') {
            gridCheckbox.removeAttribute('disabled');
        }
        else {
            gridCheckbox.setAttribute('disabled', 'disabled');
        }

        if (imageFormatSelect.value === 'png') {
            dpiSelect.removeAttribute('disabled');
            customDpi.removeAttribute('disabled');
        }
        else {
            dpiSelect.setAttribute('disabled', 'disabled');
            customDpi.setAttribute('disabled', 'disabled');
        }
    };

    mxEvent.addListener(imageFormatSelect, 'change', formatChanged);
    formatChanged();

    function checkValues() {
        if (widthInput.value * heightInput.value > MAX_AREA || widthInput.value <= 0) {
            widthInput.style.backgroundColor = 'red';
        }
        else {
            widthInput.style.backgroundColor = '';
        }

        if (widthInput.value * heightInput.value > MAX_AREA || heightInput.value <= 0) {
            heightInput.style.backgroundColor = 'red';
        }
        else {
            heightInput.style.backgroundColor = '';
        }
    };

    mxEvent.addListener(zoomInput, 'change', function () {
        zoomUserChanged = true;
        var s = Math.max(0, parseFloat(zoomInput.value) || 100) / 100;
        zoomInput.value = parseFloat((s * 100).toFixed(2));

        if (width > 0) {
            widthInput.value = Math.floor(width * s);
            heightInput.value = Math.floor(height * s);
        }
        else {
            zoomInput.value = '100';
            widthInput.value = width;
            heightInput.value = height;
        }

        checkValues();
    });

    mxEvent.addListener(widthInput, 'change', function () {
        var s = parseInt(widthInput.value) / width;

        if (s > 0) {
            zoomInput.value = parseFloat((s * 100).toFixed(2));
            heightInput.value = Math.floor(height * s);
        }
        else {
            zoomInput.value = '100';
            widthInput.value = width;
            heightInput.value = height;
        }

        checkValues();
    });

    mxEvent.addListener(heightInput, 'change', function () {
        var s = parseInt(heightInput.value) / height;

        if (s > 0) {
            zoomInput.value = parseFloat((s * 100).toFixed(2));
            widthInput.value = Math.floor(width * s);
        }
        else {
            zoomInput.value = '100';
            widthInput.value = width;
            heightInput.value = height;
        }

        checkValues();
    });

    row = document.createElement('tr');
    td = document.createElement('td');
    td.setAttribute('align', 'right');
    td.style.paddingTop = '22px';
    td.colSpan = 2;

    var saveBtn = mxUtils.button(mxResources.get('export'), mxUtils.bind(this, function () {
        if (parseInt(zoomInput.value) <= 0) {
            mxUtils.alert(mxResources.get('drawingEmpty'));
        }
        else {
            var name = nameInput.value;
            var format = imageFormatSelect.value;
            var s = Math.max(0, parseFloat(zoomInput.value) || 100) / 100;
            var b = Math.max(0, parseInt(borderInput.value));
            var bg = graph.background;
            var dpi = Math.max(1, parseInt(customDpi.value));

            if ((format == 'svg' || format == 'png' || format == 'pdf') && transparentCheckbox.checked) {
                bg = null;
            }
            else if (bg == null || bg == mxConstants.NONE) {
                bg = '#ffffff';
            }

            ExportDialog.lastBorderValue = b;
            ExportDialog.exportFile(editorUi, name, format, bg, s, b, dpi, gridCheckbox.checked);
        }
    }));
    saveBtn.className = 'geBtn gePrimaryBtn';

    var cancelBtn = mxUtils.button(mxResources.get('cancel'), function () {
        editorUi.hideDialog();
    });
    cancelBtn.className = 'geBtn';

    if (editorUi.editor.cancelFirst) {
        td.appendChild(cancelBtn);
        td.appendChild(saveBtn);
    }
    else {
        td.appendChild(saveBtn);
        td.appendChild(cancelBtn);
    }

    row.appendChild(td);
    tbody.appendChild(row);
    table.appendChild(tbody);
    this.container = table;
};

/**
 * Remembers last value for border.
 */
ExportDialog.lastBorderValue = 0;

/**
 * Global switches for the export dialog.
 */
ExportDialog.showGifOption = false;

/**
 * Global switches for the export dialog.
 */
ExportDialog.showXmlOption = true;

/**
 * Hook for getting the export format. Returns null for the default
 * intermediate XML export format or a function that returns the
 * parameter and value to be used in the request in the form
 * key=value, where value should be URL encoded.
 */
ExportDialog.exportFile = function (editorUi, name, format, bg, s, b) {

    var graph = editorUi.editor.graph;

    if (format == 'xml') {
        //ExportDialog.saveLocalFile(editorUi, mxUtils.getXml(editorUi.editor.getGraphXml()), name, format);

        var xmlString = mxUtils.getXml(editorUi.editor.getGraphXml());

        var blob = new Blob([xmlString], { type: "text/xml" });

        saveAs(blob, name);
    }
    else if (format == 'svg') {
        var svg = graph.getSvg("#FFFFFF", 1, null, null, true, null, null);

        var s = new XMLSerializer();
        var str = serializeXmlNode(svg);// s.serializeToString(svg);

        str = str.replace("[Not supported by viewer]", "");



        var blob = new Blob([str], { type: "image/svg+xml" });
        saveAs(blob, name);

        //ExportDialog.saveLocalFile(editorUi, mxUtils.getXml(graph.getSvg(bg, s, b)), name, format);
    }

    else if (format == 'png') {
        var svg = graph.getSvg("#FFFFFF", 1, null, null, true, null, null);
        var bounds = graph.getGraphBounds();
        var wid = bounds.width;
        var hei = bounds.height;

        SavePNG(svg, name, wid, hei);
    }

    else if (format == 'jpg') {

        var svg = graph.getSvg("#FFFFFF", 1, null, null, true, null, null);
        var bounds = graph.getGraphBounds();
        var wid = bounds.width;
        var hei = bounds.height;

        SaveJPG(svg, name, wid, hei);
    }
    else if (format == 'pdf') {





        let pdf = new jsPDF('p', 'mm', 'a4');



        var svg = graph.getSvg("#FFFFFF", 1, null, null, true, null, null);






        //  	var bounds = graph.getGraphBounds();

        //// New image export
        //var xmlDoc = mxUtils.createXmlDocument();
        //var root = xmlDoc.createElement('output');
        //xmlDoc.appendChild(root);

        //   // Renders graph. Offset will be multiplied with state's scale when painting state.
        //var xmlCanvas = new mxXmlCanvas2D(root);
        //xmlCanvas.translate(Math.floor((b / s - bounds.x) / graph.view.scale),
        //	Math.floor((b / s - bounds.y) / graph.view.scale));
        //xmlCanvas.scale(s / graph.view.scale);

        //var imgExport = new mxImageExport()
        //   imgExport.drawState(graph.getView().getState(graph.model.root), xmlCanvas);

        //// Puts request data together
        //      var param = 'xml=' + encodeURIComponent(mxUtils.getXml(root));
        //     // var param = 'xml=' + encodeURIComponent(b64);

        //var w = Math.ceil(bounds.width * s / graph.view.scale + 2 * b);
        //      var h = Math.ceil(bounds.height * s / graph.view.scale + 2 * b);

        var bounds = graph.getGraphBounds();
        var w = bounds.width;
        var h = bounds.height;

        var state1 = graph.view.getState(graph.model.root);
        debugger;
        
        SavePdf(svg, pdf, name, w, h);






        // Requests image if request is valid
        //if (param.length <= MAX_REQUEST_SIZE && w * h < MAX_AREA)
        //{
        editorUi.hideDialog();

        return;
        var req = new mxXmlRequest(rootUrl + '/Graph/ExportData/', 'format=' + format +
            '&filename=' + encodeURIComponent(name) +
            '&bg=' + ((bg != null) ? bg : 'none') +
            '&w=' + w + '&h=' + h + '&' + param);
        req.simulate(document, '_blank');
        //}
        //else
        //{
        //	mxUtils.alert(mxResources.get('drawingTooLarge'));
        //}
    }
};


function serializeXmlNode(xmlNode) {
    if (typeof window.XMLSerializer != "undefined") {
        return (new window.XMLSerializer()).serializeToString(xmlNode);
    } else if (typeof xmlNode.xml != "undefined") {
        return xmlNode.xml;
    }
    return "";
}

async function SavePdf(svg1, pdf, name, wid, hei) {
    

    var allImages = svg1.getElementsByTagName('image');

    for (var i = 0; i < allImages.length; i++) {

        var src = allImages[i].getAttribute('xlink:href');
        /* var val = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAQAAAAEACAYAAABccqhmAAAACXBIWXMAAAsTAAALEwEAmpwYAABCQWlUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPD94cGFja2V0IGJlZ2luPSLvu78iIGlkPSJXNU0wTXBDZWhpSHpyZVN6TlRjemtjOWQiPz4KPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iQWRvYmUgWE1QIENvcmUgNS42LWMwMTQgNzkuMTU2Nzk3LCAyMDE0LzA4LzIwLTA5OjUzOjAyICAgICAgICAiPgogICA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPgogICAgICA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIgogICAgICAgICAgICB4bWxuczp4bXA9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iCiAgICAgICAgICAgIHhtbG5zOmRjPSJodHRwOi8vcHVybC5vcmcvZGMvZWxlbWVudHMvMS4xLyIKICAgICAgICAgICAgeG1sbnM6eG1wTU09Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9tbS8iCiAgICAgICAgICAgIHhtbG5zOnN0RXZ0PSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvc1R5cGUvUmVzb3VyY2VFdmVudCMiCiAgICAgICAgICAgIHhtbG5zOnN0UmVmPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvc1R5cGUvUmVzb3VyY2VSZWYjIgogICAgICAgICAgICB4bWxuczpwaG90b3Nob3A9Imh0dHA6Ly9ucy5hZG9iZS5jb20vcGhvdG9zaG9wLzEuMC8iCiAgICAgICAgICAgIHhtbG5zOnRpZmY9Imh0dHA6Ly9ucy5hZG9iZS5jb20vdGlmZi8xLjAvIgogICAgICAgICAgICB4bWxuczpleGlmPSJodHRwOi8vbnMuYWRvYmUuY29tL2V4aWYvMS4wLyI+CiAgICAgICAgIDx4bXA6Q3JlYXRlRGF0ZT4yMDE1LTExLTIxVDA1OjM0OjE1WjwveG1wOkNyZWF0ZURhdGU+CiAgICAgICAgIDx4bXA6TW9kaWZ5RGF0ZT4yMDE1LTExLTIxVDEyOjQwOjAxKzA1OjMwPC94bXA6TW9kaWZ5RGF0ZT4KICAgICAgICAgPHhtcDpNZXRhZGF0YURhdGU+MjAxNS0xMS0yMVQxMjo0MDowMSswNTozMDwveG1wOk1ldGFkYXRhRGF0ZT4KICAgICAgICAgPHhtcDpDcmVhdG9yVG9vbD5BZG9iZSBQaG90b3Nob3AgQ0MgMjAxNCAoTWFjaW50b3NoKTwveG1wOkNyZWF0b3JUb29sPgogICAgICAgICA8ZGM6Zm9ybWF0PmltYWdlL3BuZzwvZGM6Zm9ybWF0PgogICAgICAgICA8eG1wTU06SGlzdG9yeT4KICAgICAgICAgICAgPHJkZjpTZXE+CiAgICAgICAgICAgICAgIDxyZGY6bGkgcmRmOnBhcnNlVHlwZT0iUmVzb3VyY2UiPgogICAgICAgICAgICAgICAgICA8c3RFdnQ6YWN0aW9uPmNvbnZlcnRlZDwvc3RFdnQ6YWN0aW9uPgogICAgICAgICAgICAgICAgICA8c3RFdnQ6cGFyYW1ldGVycz5mcm9tIGltYWdlL3BuZyB0byBhcHBsaWNhdGlvbi92bmQuYWRvYmUucGhvdG9zaG9wPC9zdEV2dDpwYXJhbWV0ZXJzPgogICAgICAgICAgICAgICA8L3JkZjpsaT4KICAgICAgICAgICAgICAgPHJkZjpsaSByZGY6cGFyc2VUeXBlPSJSZXNvdXJjZSI+CiAgICAgICAgICAgICAgICAgIDxzdEV2dDphY3Rpb24+c2F2ZWQ8L3N0RXZ0OmFjdGlvbj4KICAgICAgICAgICAgICAgICAgPHN0RXZ0Omluc3RhbmNlSUQ+eG1wLmlpZDpGMjEwRTIyQzEzMjA2ODExODIyQUEwNjcyQ0Y4NjgyMzwvc3RFdnQ6aW5zdGFuY2VJRD4KICAgICAgICAgICAgICAgICAgPHN0RXZ0OndoZW4+MjAxNS0xMS0yMVQxMjozMTozNCswNTozMDwvc3RFdnQ6d2hlbj4KICAgICAgICAgICAgICAgICAgPHN0RXZ0OmNoYW5nZWQ+Lzwvc3RFdnQ6Y2hhbmdlZD4KICAgICAgICAgICAgICAgPC9yZGY6bGk+CiAgICAgICAgICAgICAgIDxyZGY6bGkgcmRmOnBhcnNlVHlwZT0iUmVzb3VyY2UiPgogICAgICAgICAgICAgICAgICA8c3RFdnQ6YWN0aW9uPmNvbnZlcnRlZDwvc3RFdnQ6YWN0aW9uPgogICAgICAgICAgICAgICAgICA8c3RFdnQ6cGFyYW1ldGVycz5mcm9tIGltYWdlL3BuZyB0byBhcHBsaWNhdGlvbi92bmQuYWRvYmUucGhvdG9zaG9wPC9zdEV2dDpwYXJhbWV0ZXJzPgogICAgICAgICAgICAgICA8L3JkZjpsaT4KICAgICAgICAgICAgICAgPHJkZjpsaSByZGY6cGFyc2VUeXBlPSJSZXNvdXJjZSI+CiAgICAgICAgICAgICAgICAgIDxzdEV2dDphY3Rpb24+c2F2ZWQ8L3N0RXZ0OmFjdGlvbj4KICAgICAgICAgICAgICAgICAgPHN0RXZ0Omluc3RhbmNlSUQ+eG1wLmlpZDpGMzEwRTIyQzEzMjA2ODExODIyQUEwNjcyQ0Y4NjgyMzwvc3RFdnQ6aW5zdGFuY2VJRD4KICAgICAgICAgICAgICAgICAgPHN0RXZ0OndoZW4+MjAxNS0xMS0yMVQxMjozMTozNCswNTozMDwvc3RFdnQ6d2hlbj4KICAgICAgICAgICAgICAgICAgPHN0RXZ0OmNoYW5nZWQ+Lzwvc3RFdnQ6Y2hhbmdlZD4KICAgICAgICAgICAgICAgPC9yZGY6bGk+CiAgICAgICAgICAgICAgIDxyZGY6bGkgcmRmOnBhcnNlVHlwZT0iUmVzb3VyY2UiPgogICAgICAgICAgICAgICAgICA8c3RFdnQ6YWN0aW9uPnNhdmVkPC9zdEV2dDphY3Rpb24+CiAgICAgICAgICAgICAgICAgIDxzdEV2dDppbnN0YW5jZUlEPnhtcC5paWQ6ZTM5OTZmYmItZTgwMS00N2Y1LTg5YjgtNTUwZjhhOTg1ODMwPC9zdEV2dDppbnN0YW5jZUlEPgogICAgICAgICAgICAgICAgICA8c3RFdnQ6d2hlbj4yMDE1LTExLTIxVDEyOjQwOjAxKzA1OjMwPC9zdEV2dDp3aGVuPgogICAgICAgICAgICAgICAgICA8c3RFdnQ6c29mdHdhcmVBZ2VudD5BZG9iZSBQaG90b3Nob3AgQ0MgMjAxNCAoTWFjaW50b3NoKTwvc3RFdnQ6c29mdHdhcmVBZ2VudD4KICAgICAgICAgICAgICAgICAgPHN0RXZ0OmNoYW5nZWQ+Lzwvc3RFdnQ6Y2hhbmdlZD4KICAgICAgICAgICAgICAgPC9yZGY6bGk+CiAgICAgICAgICAgICAgIDxyZGY6bGkgcmRmOnBhcnNlVHlwZT0iUmVzb3VyY2UiPgogICAgICAgICAgICAgICAgICA8c3RFdnQ6YWN0aW9uPmNvbnZlcnRlZDwvc3RFdnQ6YWN0aW9uPgogICAgICAgICAgICAgICAgICA8c3RFdnQ6cGFyYW1ldGVycz5mcm9tIGFwcGxpY2F0aW9uL3ZuZC5hZG9iZS5waG90b3Nob3AgdG8gaW1hZ2UvcG5nPC9zdEV2dDpwYXJhbWV0ZXJzPgogICAgICAgICAgICAgICA8L3JkZjpsaT4KICAgICAgICAgICAgICAgPHJkZjpsaSByZGY6cGFyc2VUeXBlPSJSZXNvdXJjZSI+CiAgICAgICAgICAgICAgICAgIDxzdEV2dDphY3Rpb24+ZGVyaXZlZDwvc3RFdnQ6YWN0aW9uPgogICAgICAgICAgICAgICAgICA8c3RFdnQ6cGFyYW1ldGVycz5jb252ZXJ0ZWQgZnJvbSBhcHBsaWNhdGlvbi92bmQuYWRvYmUucGhvdG9zaG9wIHRvIGltYWdlL3BuZzwvc3RFdnQ6cGFyYW1ldGVycz4KICAgICAgICAgICAgICAgPC9yZGY6bGk+CiAgICAgICAgICAgICAgIDxyZGY6bGkgcmRmOnBhcnNlVHlwZT0iUmVzb3VyY2UiPgogICAgICAgICAgICAgICAgICA8c3RFdnQ6YWN0aW9uPnNhdmVkPC9zdEV2dDphY3Rpb24+CiAgICAgICAgICAgICAgICAgIDxzdEV2dDppbnN0YW5jZUlEPnhtcC5paWQ6MTNjNDEyMmEtM2RmMS00Mzg4LTgzMzctZDk5ZTI2MjZmOGQzPC9zdEV2dDppbnN0YW5jZUlEPgogICAgICAgICAgICAgICAgICA8c3RFdnQ6d2hlbj4yMDE1LTExLTIxVDEyOjQwOjAxKzA1OjMwPC9zdEV2dDp3aGVuPgogICAgICAgICAgICAgICAgICA8c3RFdnQ6c29mdHdhcmVBZ2VudD5BZG9iZSBQaG90b3Nob3AgQ0MgMjAxNCAoTWFjaW50b3NoKTwvc3RFdnQ6c29mdHdhcmVBZ2VudD4KICAgICAgICAgICAgICAgICAgPHN0RXZ0OmNoYW5nZWQ+Lzwvc3RFdnQ6Y2hhbmdlZD4KICAgICAgICAgICAgICAgPC9yZGY6bGk+CiAgICAgICAgICAgIDwvcmRmOlNlcT4KICAgICAgICAgPC94bXBNTTpIaXN0b3J5PgogICAgICAgICA8eG1wTU06RGVyaXZlZEZyb20gcmRmOnBhcnNlVHlwZT0iUmVzb3VyY2UiPgogICAgICAgICAgICA8c3RSZWY6aW5zdGFuY2VJRD54bXAuaWlkOmUzOTk2ZmJiLWU4MDEtNDdmNS04OWI4LTU1MGY4YTk4NTgzMDwvc3RSZWY6aW5zdGFuY2VJRD4KICAgICAgICAgICAgPHN0UmVmOmRvY3VtZW50SUQ+eG1wLmRpZDpGMjEwRTIyQzEzMjA2ODExODIyQUEwNjcyQ0Y4NjgyMzwvc3RSZWY6ZG9jdW1lbnRJRD4KICAgICAgICAgICAgPHN0UmVmOm9yaWdpbmFsRG9jdW1lbnRJRD54bXAuZGlkOkYyMTBFMjJDMTMyMDY4MTE4MjJBQTA2NzJDRjg2ODIzPC9zdFJlZjpvcmlnaW5hbERvY3VtZW50SUQ+CiAgICAgICAgIDwveG1wTU06RGVyaXZlZEZyb20+CiAgICAgICAgIDx4bXBNTTpEb2N1bWVudElEPmFkb2JlOmRvY2lkOnBob3Rvc2hvcDo0ZTZiYTI5Mi1kMGFkLTExNzgtOGU3OS04ZjUxMjZiM2FlYjU8L3htcE1NOkRvY3VtZW50SUQ+CiAgICAgICAgIDx4bXBNTTpJbnN0YW5jZUlEPnhtcC5paWQ6MTNjNDEyMmEtM2RmMS00Mzg4LTgzMzctZDk5ZTI2MjZmOGQzPC94bXBNTTpJbnN0YW5jZUlEPgogICAgICAgICA8eG1wTU06T3JpZ2luYWxEb2N1bWVudElEPnhtcC5kaWQ6RjIxMEUyMkMxMzIwNjgxMTgyMkFBMDY3MkNGODY4MjM8L3htcE1NOk9yaWdpbmFsRG9jdW1lbnRJRD4KICAgICAgICAgPHBob3Rvc2hvcDpDb2xvck1vZGU+MzwvcGhvdG9zaG9wOkNvbG9yTW9kZT4KICAgICAgICAgPHRpZmY6T3JpZW50YXRpb24+MTwvdGlmZjpPcmllbnRhdGlvbj4KICAgICAgICAgPHRpZmY6WFJlc29sdXRpb24+NzIwMDAwLzEwMDAwPC90aWZmOlhSZXNvbHV0aW9uPgogICAgICAgICA8dGlmZjpZUmVzb2x1dGlvbj43MjAwMDAvMTAwMDA8L3RpZmY6WVJlc29sdXRpb24+CiAgICAgICAgIDx0aWZmOlJlc29sdXRpb25Vbml0PjI8L3RpZmY6UmVzb2x1dGlvblVuaXQ+CiAgICAgICAgIDxleGlmOkNvbG9yU3BhY2U+NjU1MzU8L2V4aWY6Q29sb3JTcGFjZT4KICAgICAgICAgPGV4aWY6UGl4ZWxYRGltZW5zaW9uPjI1NjwvZXhpZjpQaXhlbFhEaW1lbnNpb24+CiAgICAgICAgIDxleGlmOlBpeGVsWURpbWVuc2lvbj4yNTY8L2V4aWY6UGl4ZWxZRGltZW5zaW9uPgogICAgICA8L3JkZjpEZXNjcmlwdGlvbj4KICAgPC9yZGY6UkRGPgo8L3g6eG1wbWV0YT4KICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAKPD94cGFja2V0IGVuZD0idyI/PmeXOsMAAAAgY0hSTQAAeiUAAICDAAD5/wAAgOkAAHUwAADqYAAAOpgAABdvkl/FRgAADgxJREFUeNrs3XmsHVUBx/Hvw5ZCSxcKlLII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";*/
        await getBase64ImageFromUrl(src)
            .then(result => svg1.getElementsByTagName('image')[i].setAttribute('xlink:href', result))
            .catch(err => console.error(err));




    }


    var s = new XMLSerializer();
    var str = serializeXmlNode(svg1);// s.serializeToString(svg);

    str = str.replace("[Not supported by viewer]", "");


    //var canvas1 = document.getElementById("canvasPdf");
    //canvas1.width = wid;
    //canvas1.height = hei;


    //const ctx = canvas1.getContext('2d');
    //debugger;
    var svgImage = new Image();
    svgImage.src = 'data:image/svg+xml;charset=utf-8,' + encodeURIComponent(str);
    svgImage.onload = function () {
       
       
      

        // create a canvas or get it from the page
        var canvas = document.createElement("canvas");
        // set the resolution (number of pixels)
        canvas.width = wid + 2000; canvas.height = hei + 2000;
        // set the display size
        // canvas.style.width = wid + "px"; canvas.style.height = hei + "px";
        // get the rendering context


        var context = canvas.getContext("2d");

        context.fillStyle = "#FFFFFF";
        context.fillRect(0, 0, canvas.width, canvas.height);

        var scale = Math.min(canvas.width / wid, canvas.height / hei);
        // get the top left position of the image
        var x = (canvas.width / 2) - (wid / 2) * scale;
        var y = (canvas.height / 2) - (hei / 2) * scale;

        context.setTransform(scale, 0, 0, scale, 0, 0);

        context.drawImage(svgImage, 0, 0, wid, hei);



        var img = new Image();
        img.src = $(canvas).get(0).toDataURL('image/jpeg', 1.0);


        $(canvas).remove();
        img.onload = function () {

            debugger;
            const imgProps = pdf.getImageProperties(img);
            const margin = 0.05;

            const pdfWidth = pdf.internal.pageSize.getWidth() * (1 - margin);
            const pdfHeight = pdf.internal.pageSize.getHeight() * (1 - margin);

            const x = pdf.internal.pageSize.getWidth() * (margin / 2);
            const y = pdf.internal.pageSize.getHeight() * (margin / 2);

            const widthRatio = pdfWidth / imgProps.width;
            const heightRatio = pdfHeight / imgProps.height;
            const ratio = Math.min(widthRatio, heightRatio);

            const w = imgProps.width * ratio;
            const h = imgProps.height * ratio;

            pdf.addImage(img, "JPEG", x, y, w, h);
            pdf.save(name);
            return;




          //  debugger;


          //   var pagewidth = pdf.internal.pageSize.getWidth();
          //  var pageheight = pdf.internal.pageSize.getHeight();

          // // var width = Math.floor(wid * 0.2665);
          //  //var height = Math.floor(hei * 0.2665);

          //  var width = Math.floor(wid );
          //  var height = Math.floor(hei );

          //  //var maxheight = 1056;
          //  //var maxwidth = 816;

          //  //var imgwidth = width ;
          //  //var imgheight = height;

          //  //if (imgwidth > maxwidth)
          //  //    imgwidth = maxwidth;

          //  //if (imgheight > maxheight)
          //  //    imgheight = maxheight;

           

           

          //  //$(img).resizeAndCrop();

          //  //const pdf1 = new jsPDF({
          //  //    orientation: maxheight > maxwidth ? "portrait" : "landscape",
          //  //    unit: "px",
          //  //    format: [maxheight, maxwidth]
          //  //});
          //  pdf.addImage(img, 'JPEG', 0, 0, pagewidth-1, pageheight);

          ////  pdf1.addImage(img, 'JPEG', 5, 10, maxwidth, maxheight, undefined, 'FAST');

          //  pdf.save(name);





        }
        return;



        //ctx.drawImage(svgImage, 2, 10);

        //console.log($("#canvasPdf").get(0).toDataURL());

        //var link = document.createElement('a');
        //link.download = name;
        //link.href = $("#canvasPdf").get(0).toDataURL();
        //link.click();
        //link.remove();
        ////$("#png1").attr("src", $("#canvasPdf").get(0).toDataURL());
    }






}

function imageToDataUri(img, width, height) {

    // create an off-screen canvas
    var canvas = document.createElement('canvas'),
        ctx = canvas.getContext('2d');

    // set its dimension to target size
    canvas.width = width;
    canvas.height = height;

    // draw source image into the off-screen canvas:
    ctx.drawImage(img, 0, 0, width, height);

    // encode image to data-uri with base64 version of compressed image
    return canvas.toDataURL();
}

// Download the given image URL as a PDF file.
function savePDF(imageDataURL) {
    // Get the dimensions of the image.
    var image = new Image();

    image.onload = function () {
        let pageWidth = image.naturalWidth;
        let pageHeight = image.naturalHeight;

        // Create a new PDF with the same dimensions as the image.
        const pdf = new jsPDF({
            orientation: pageHeight > pageWidth ? "portrait" : "landscape",
            unit: "px",
            format: [pageHeight, pageWidth]
        });

        // Add the image to the PDF with dimensions equal to the internal dimensions of the page.
        pdf.addImage(imageDataURL, 0, 0, pdf.internal.pageSize.getWidth(), pdf.internal.pageSize.getHeight());

        // Save the PDF with the filename specified here:
        pdf.save("index.pdf");
    }

    image.src = imageDataURL;
}

async function getBase64ImageFromUrl(imageUrl) {
    var res = await fetch(imageUrl);
    var blob = await res.blob();

    return new Promise((resolve, reject) => {
        var reader = new FileReader();
        reader.addEventListener("load", function () {
            resolve(reader.result);
        }, false);

        reader.onerror = () => {
            return reject(this);
        };
        reader.readAsDataURL(blob);
    })
}


async function SavePNG(svg1, name, wid, hei) {





    var allImages = svg1.getElementsByTagName('image');

    for (var i = 0; i < allImages.length; i++) {

        var src = allImages[i].getAttribute('xlink:href');
        /* var val = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAQAAAAEACAYAAABccqhmAAAACXBIWXMAAAsTAAALEwEAmpwYAABCQWlUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPD94cGFja2V0IGJlZ2luPSLvu78iIGlkPSJXNU0wTXBDZWhpSHpyZVN6TlRjemtjOWQiPz4KPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iQWRvYmUgWE1QIENvcmUgNS42LWMwMTQgNzkuMTU2Nzk3LCAyMDE0LzA4LzIwLTA5OjUzOjAyICAgICAgICAiPgogICA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPgogICAgICA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIgogICAgICAgICAgICB4bWxuczp4bXA9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iCiAgICAgICAgICAgIHhtbG5zOmRjPSJodHRwOi8vcHVybC5vcmcvZGMvZWxlbWVudHMvMS4xLyIKICAgICAgICAgICAgeG1sbnM6eG1wTU09Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9tbS8iCiAgICAgICAgICAgIHhtbG5zOnN0RXZ0PSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvc1R5cGUvUmVzb3VyY2VFdmVudCMiCiAgICAgICAgICAgIHhtbG5zOnN0UmVmPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvc1R5cGUvUmVzb3VyY2VSZWYjIgogICAgICAgICAgICB4bWxuczpwaG90b3Nob3A9Imh0dHA6Ly9ucy5hZG9iZS5jb20vcGhvdG9zaG9wLzEuMC8iCiAgICAgICAgICAgIHhtbG5zOnRpZmY9Imh0dHA6Ly9ucy5hZG9iZS5jb20vdGlmZi8xLjAvIgogICAgICAgICAgICB4bWxuczpleGlmPSJodHRwOi8vbnMuYWRvYmUuY29tL2V4aWYvMS4wLyI+CiAgICAgICAgIDx4bXA6Q3JlYXRlRGF0ZT4yMDE1LTExLTIxVDA1OjM0OjE1WjwveG1wOkNyZWF0ZURhdGU+CiAgICAgICAgIDx4bXA6TW9kaWZ5RGF0ZT4yMDE1LTExLTIxVDEyOjQwOjAxKzA1OjMwPC94bXA6TW9kaWZ5RGF0ZT4KICAgICAgICAgPHhtcDpNZXRhZGF0YURhdGU+MjAxNS0xMS0yMVQxMjo0MDowMSswNTozMDwveG1wOk1ldGFkYXRhRGF0ZT4KICAgICAgICAgPHhtcDpDcmVhdG9yVG9vbD5BZG9iZSBQaG90b3Nob3AgQ0MgMjAxNCAoTWFjaW50b3NoKTwveG1wOkNyZWF0b3JUb29sPgogICAgICAgICA8ZGM6Zm9ybWF0PmltYWdlL3BuZzwvZGM6Zm9ybWF0PgogICAgICAgICA8eG1wTU06SGlzdG9yeT4KICAgICAgICAgICAgPHJkZjpTZXE+CiAgICAgICAgICAgICAgIDxyZGY6bGkgcmRmOnBhcnNlVHlwZT0iUmVzb3VyY2UiPgogICAgICAgICAgICAgICAgICA8c3RFdnQ6YWN0aW9uPmNvbnZlcnRlZDwvc3RFdnQ6YWN0aW9uPgogICAgICAgICAgICAgICAgICA8c3RFdnQ6cGFyYW1ldGVycz5mcm9tIGltYWdlL3BuZyB0byBhcHBsaWNhdGlvbi92bmQuYWRvYmUucGhvdG9zaG9wPC9zdEV2dDpwYXJhbWV0ZXJzPgogICAgICAgICAgICAgICA8L3JkZjpsaT4KICAgICAgICAgICAgICAgPHJkZjpsaSByZGY6cGFyc2VUeXBlPSJSZXNvdXJjZSI+CiAgICAgICAgICAgICAgICAgIDxzdEV2dDphY3Rpb24+c2F2ZWQ8L3N0RXZ0OmFjdGlvbj4KICAgICAgICAgICAgICAgICAgPHN0RXZ0Omluc3RhbmNlSUQ+eG1wLmlpZDpGMjEwRTIyQzEzMjA2ODExODIyQUEwNjcyQ0Y4NjgyMzwvc3RFdnQ6aW5zdGFuY2VJRD4KICAgICAgICAgICAgICAgICAgPHN0RXZ0OndoZW4+MjAxNS0xMS0yMVQxMjozMTozNCswNTozMDwvc3RFdnQ6d2hlbj4KICAgICAgICAgICAgICAgICAgPHN0RXZ0OmNoYW5nZWQ+Lzwvc3RFdnQ6Y2hhbmdlZD4KICAgICAgICAgICAgICAgPC9yZGY6bGk+CiAgICAgICAgICAgICAgIDxyZGY6bGkgcmRmOnBhcnNlVHlwZT0iUmVzb3VyY2UiPgogICAgICAgICAgICAgICAgICA8c3RFdnQ6YWN0aW9uPmNvbnZlcnRlZDwvc3RFdnQ6YWN0aW9uPgogICAgICAgICAgICAgICAgICA8c3RFdnQ6cGFyYW1ldGVycz5mcm9tIGltYWdlL3BuZyB0byBhcHBsaWNhdGlvbi92bmQuYWRvYmUucGhvdG9zaG9wPC9zdEV2dDpwYXJhbWV0ZXJzPgogICAgICAgICAgICAgICA8L3JkZjpsaT4KICAgICAgICAgICAgICAgPHJkZjpsaSByZGY6cGFyc2VUeXBlPSJSZXNvdXJjZSI+CiAgICAgICAgICAgICAgICAgIDxzdEV2dDphY3Rpb24+c2F2ZWQ8L3N0RXZ0OmFjdGlvbj4KICAgICAgICAgICAgICAgICAgPHN0RXZ0Omluc3RhbmNlSUQ+eG1wLmlpZDpGMzEwRTIyQzEzMjA2ODExODIyQUEwNjcyQ0Y4NjgyMzwvc3RFdnQ6aW5zdGFuY2VJRD4KICAgICAgICAgICAgICAgICAgPHN0RXZ0OndoZW4+MjAxNS0xMS0yMVQxMjozMTozNCswNTozMDwvc3RFdnQ6d2hlbj4KICAgICAgICAgICAgICAgICAgPHN0RXZ0OmNoYW5nZWQ+Lzwvc3RFdnQ6Y2hhbmdlZD4KICAgICAgICAgICAgICAgPC9yZGY6bGk+CiAgICAgICAgICAgICAgIDxyZGY6bGkgcmRmOnBhcnNlVHlwZT0iUmVzb3VyY2UiPgogICAgICAgICAgICAgICAgICA8c3RFdnQ6YWN0aW9uPnNhdmVkPC9zdEV2dDphY3Rpb24+CiAgICAgICAgICAgICAgICAgIDxzdEV2dDppbnN0YW5jZUlEPnhtcC5paWQ6ZTM5OTZmYmItZTgwMS00N2Y1LTg5YjgtNTUwZjhhOTg1ODMwPC9zdEV2dDppbnN0YW5jZUlEPgogICAgICAgICAgICAgICAgICA8c3RFdnQ6d2hlbj4yMDE1LTExLTIxVDEyOjQwOjAxKzA1OjMwPC9zdEV2dDp3aGVuPgogICAgICAgICAgICAgICAgICA8c3RFdnQ6c29mdHdhcmVBZ2VudD5BZG9iZSBQaG90b3Nob3AgQ0MgMjAxNCAoTWFjaW50b3NoKTwvc3RFdnQ6c29mdHdhcmVBZ2VudD4KICAgICAgICAgICAgICAgICAgPHN0RXZ0OmNoYW5nZWQ+Lzwvc3RFdnQ6Y2hhbmdlZD4KICAgICAgICAgICAgICAgPC9yZGY6bGk+CiAgICAgICAgICAgICAgIDxyZGY6bGkgcmRmOnBhcnNlVHlwZT0iUmVzb3VyY2UiPgogICAgICAgICAgICAgICAgICA8c3RFdnQ6YWN0aW9uPmNvbnZlcnRlZDwvc3RFdnQ6YWN0aW9uPgogICAgICAgICAgICAgICAgICA8c3RFdnQ6cGFyYW1ldGVycz5mcm9tIGFwcGxpY2F0aW9uL3ZuZC5hZG9iZS5waG90b3Nob3AgdG8gaW1hZ2UvcG5nPC9zdEV2dDpwYXJhbWV0ZXJzPgogICAgICAgICAgICAgICA8L3JkZjpsaT4KICAgICAgICAgICAgICAgPHJkZjpsaSByZGY6cGFyc2VUeXBlPSJSZXNvdXJjZSI+CiAgICAgICAgICAgICAgICAgIDxzdEV2dDphY3Rpb24+ZGVyaXZlZDwvc3RFdnQ6YWN0aW9uPgogICAgICAgICAgICAgICAgICA8c3RFdnQ6cGFyYW1ldGVycz5jb252ZXJ0ZWQgZnJvbSBhcHBsaWNhdGlvbi92bmQuYWRvYmUucGhvdG9zaG9wIHRvIGltYWdlL3BuZzwvc3RFdnQ6cGFyYW1ldGVycz4KICAgICAgICAgICAgICAgPC9yZGY6bGk+CiAgICAgICAgICAgICAgIDxyZGY6bGkgcmRmOnBhcnNlVHlwZT0iUmVzb3VyY2UiPgogICAgICAgICAgICAgICAgICA8c3RFdnQ6YWN0aW9uPnNhdmVkPC9zdEV2dDphY3Rpb24+CiAgICAgICAgICAgICAgICAgIDxzdEV2dDppbnN0YW5jZUlEPnhtcC5paWQ6MTNjNDEyMmEtM2RmMS00Mzg4LTgzMzctZDk5ZTI2MjZmOGQzPC9zdEV2dDppbnN0YW5jZUlEPgogICAgICAgICAgICAgICAgICA8c3RFdnQ6d2hlbj4yMDE1LTExLTIxVDEyOjQwOjAxKzA1OjMwPC9zdEV2dDp3aGVuPgogICAgICAgICAgICAgICAgICA8c3RFdnQ6c29mdHdhcmVBZ2VudD5BZG9iZSBQaG90b3Nob3AgQ0MgMjAxNCAoTWFjaW50b3NoKTwvc3RFdnQ6c29mdHdhcmVBZ2VudD4KICAgICAgICAgICAgICAgICAgPHN0RXZ0OmNoYW5nZWQ+Lzwvc3RFdnQ6Y2hhbmdlZD4KICAgICAgICAgICAgICAgPC9yZGY6bGk+CiAgICAgICAgICAgIDwvcmRmOlNlcT4KICAgICAgICAgPC94bXBNTTpIaXN0b3J5PgogICAgICAgICA8eG1wTU06RGVyaXZlZEZyb20gcmRmOnBhcnNlVHlwZT0iUmVzb3VyY2UiPgogICAgICAgICAgICA8c3RSZWY6aW5zdGFuY2VJRD54bXAuaWlkOmUzOTk2ZmJiLWU4MDEtNDdmNS04OWI4LTU1MGY4YTk4NTgzMDwvc3RSZWY6aW5zdGFuY2VJRD4KICAgICAgICAgICAgPHN0UmVmOmRvY3VtZW50SUQ+eG1wLmRpZDpGMjEwRTIyQzEzMjA2ODExODIyQUEwNjcyQ0Y4NjgyMzwvc3RSZWY6ZG9jdW1lbnRJRD4KICAgICAgICAgICAgPHN0UmVmOm9yaWdpbmFsRG9jdW1lbnRJRD54bXAuZGlkOkYyMTBFMjJDMTMyMDY4MTE4MjJBQTA2NzJDRjg2ODIzPC9zdFJlZjpvcmlnaW5hbERvY3VtZW50SUQ+CiAgICAgICAgIDwveG1wTU06RGVyaXZlZEZyb20+CiAgICAgICAgIDx4bXBNTTpEb2N1bWVudElEPmFkb2JlOmRvY2lkOnBob3Rvc2hvcDo0ZTZiYTI5Mi1kMGFkLTExNzgtOGU3OS04ZjUxMjZiM2FlYjU8L3htcE1NOkRvY3VtZW50SUQ+CiAgICAgICAgIDx4bXBNTTpJbnN0YW5jZUlEPnhtcC5paWQ6MTNjNDEyMmEtM2RmMS00Mzg4LTgzMzctZDk5ZTI2MjZmOGQzPC94bXBNTTpJbnN0YW5jZUlEPgogICAgICAgICA8eG1wTU06T3JpZ2luYWxEb2N1bWVudElEPnhtcC5kaWQ6RjIxMEUyMkMxMzIwNjgxMTgyMkFBMDY3MkNGODY4MjM8L3htcE1NOk9yaWdpbmFsRG9jdW1lbnRJRD4KICAgICAgICAgPHBob3Rvc2hvcDpDb2xvck1vZGU+MzwvcGhvdG9zaG9wOkNvbG9yTW9kZT4KICAgICAgICAgPHRpZmY6T3JpZW50YXRpb24+MTwvdGlmZjpPcmllbnRhdGlvbj4KICAgICAgICAgPHRpZmY6WFJlc29sdXRpb24+NzIwMDAwLzEwMDAwPC90aWZmOlhSZXNvbHV0aW9uPgogICAgICAgICA8dGlmZjpZUmVzb2x1dGlvbj43MjAwMDAvMTAwMDA8L3RpZmY6WVJlc29sdXRpb24+CiAgICAgICAgIDx0aWZmOlJlc29sdXRpb25Vbml0PjI8L3RpZmY6UmVzb2x1dGlvblVuaXQ+CiAgICAgICAgIDxleGlmOkNvbG9yU3BhY2U+NjU1MzU8L2V4aWY6Q29sb3JTcGFjZT4KICAgICAgICAgPGV4aWY6UGl4ZWxYRGltZW5zaW9uPjI1NjwvZXhpZjpQaXhlbFhEaW1lbnNpb24+CiAgICAgICAgIDxleGlmOlBpeGVsWURpbWVuc2lvbj4yNTY8L2V4aWY6UGl4ZWxZRGltZW5zaW9uPgogICAgICA8L3JkZjpEZXNjcmlwdGlvbj4KICAgPC9yZGY6UkRGPgo8L3g6eG1wbWV0YT4KICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAKPD94cGFja2V0IGVuZD0idyI/PmeXOsMAAAAgY0hSTQAAeiUAAICDAAD5/wAAgOkAAHUwAADqYAAAOpgAABdvkl/FRgAADgxJREFUeNrs3XmsHVUBx/Hvw5ZCSxcKlLII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";*/
        await getBase64ImageFromUrl(src)
            .then(result => svg1.getElementsByTagName('image')[i].setAttribute('xlink:href', result))
            .catch(err => console.error(err));




    }




    var s = new XMLSerializer();
    var str = serializeXmlNode(svg1);// s.serializeToString(svg);

    str = str.replace("[Not supported by viewer]", "");


    //var canvas1 = document.getElementById("canvasPdf");
    //canvas1.width = wid;
    //canvas1.height = hei;



    //const ctx = canvas1.getContext('2d');
    debugger;
    var svgImage = new Image();
    svgImage.src = 'data:image/svg+xml;charset=utf-8,' + encodeURIComponent(str);
    svgImage.onload = function () {
        debugger;
        // create a canvas or get it from the page
        // create a canvas or get it from the page
        var canvas = document.createElement("canvas");
        // set the resolution (number of pixels)
        canvas.width = wid + 2000; canvas.height = hei + 2000;


        canvas.width = canvas.width * devicePixelRatio;
        canvas.height = canvas.height * devicePixelRatio;



        // set the display size
        canvas.style.width = (wid+2000) + "px"; canvas.style.height = (hei+2000) + "px";
        // get the rendering context


        var context = canvas.getContext("2d");

        context.fillStyle = "#FFFFFF";
        context.fillRect(0, 0, canvas.width, canvas.height);

        var scale = Math.min(canvas.width / wid, canvas.height / hei);

        if (scale > 6) {
            scale = 3;
        }
        // get the top left position of the image
        var x = (canvas.width / 2) - (wid / 2) * scale;
        var y = (canvas.height / 2) - (hei / 2) * scale;

        context.setTransform(scale, 0, 0, scale, 0, 0);

        context.scale(devicePixelRatio, devicePixelRatio);





        context.drawImage(svgImage, 0, 0, wid, hei);




        var img = new Image();
        img.src = $(canvas).get(0).toDataURL();


        $(canvas).remove();


        img.onload = function ()
        {


            //img.width = wid/1.2;
            //img.height = hei/1.2;

            img.style.imageRendering = "-moz-crisp-edges";


            $(img).resizeAndCrop();



            var link = document.createElement('a');
            link.download = name;
            link.href = img.src;
            link.click();
            link.remove();







        }
        //if (alreadydone == true) {

        //        debugger;
        //        var link = document.createElement('a');
        //        link.download = name;
        //        link.href = img1.src;
        //        link.click();
        //        link.remove();
        //        return;

        //}











    }







}

async function SaveJPG(svg1, name, wid, hei) {





    var allImages = svg1.getElementsByTagName('image');

    for (var i = 0; i < allImages.length; i++) {

        var src = allImages[i].getAttribute('xlink:href');
        /* var val = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAQAAAAEACAYAAABccqhmAAAACXBIWXMAAAsTAAALEwEAmpwYAABCQWlUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPD94cGFja2V0IGJlZ2luPSLvu78iIGlkPSJXNU0wTXBDZWhpSHpyZVN6TlRjemtjOWQiPz4KPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iQWRvYmUgWE1QIENvcmUgNS42LWMwMTQgNzkuMTU2Nzk3LCAyMDE0LzA4LzIwLTA5OjUzOjAyICAgICAgICAiPgogICA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPgogICAgICA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIgogICAgICAgICAgICB4bWxuczp4bXA9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iCiAgICAgICAgICAgIHhtbG5zOmRjPSJodHRwOi8vcHVybC5vcmcvZGMvZWxlbWVudHMvMS4xLyIKICAgICAgICAgICAgeG1sbnM6eG1wTU09Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9tbS8iCiAgICAgICAgICAgIHhtbG5zOnN0RXZ0PSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvc1R5cGUvUmVzb3VyY2VFdmVudCMiCiAgICAgICAgICAgIHhtbG5zOnN0UmVmPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvc1R5cGUvUmVzb3VyY2VSZWYjIgogICAgICAgICAgICB4bWxuczpwaG90b3Nob3A9Imh0dHA6Ly9ucy5hZG9iZS5jb20vcGhvdG9zaG9wLzEuMC8iCiAgICAgICAgICAgIHhtbG5zOnRpZmY9Imh0dHA6Ly9ucy5hZG9iZS5jb20vdGlmZi8xLjAvIgogICAgICAgICAgICB4bWxuczpleGlmPSJodHRwOi8vbnMuYWRvYmUuY29tL2V4aWYvMS4wLyI+CiAgICAgICAgIDx4bXA6Q3JlYXRlRGF0ZT4yMDE1LTExLTIxVDA1OjM0OjE1WjwveG1wOkNyZWF0ZURhdGU+CiAgICAgICAgIDx4bXA6TW9kaWZ5RGF0ZT4yMDE1LTExLTIxVDEyOjQwOjAxKzA1OjMwPC94bXA6TW9kaWZ5RGF0ZT4KICAgICAgICAgPHhtcDpNZXRhZGF0YURhdGU+MjAxNS0xMS0yMVQxMjo0MDowMSswNTozMDwveG1wOk1ldGFkYXRhRGF0ZT4KICAgICAgICAgPHhtcDpDcmVhdG9yVG9vbD5BZG9iZSBQaG90b3Nob3AgQ0MgMjAxNCAoTWFjaW50b3NoKTwveG1wOkNyZWF0b3JUb29sPgogICAgICAgICA8ZGM6Zm9ybWF0PmltYWdlL3BuZzwvZGM6Zm9ybWF0PgogICAgICAgICA8eG1wTU06SGlzdG9yeT4KICAgICAgICAgICAgPHJkZjpTZXE+CiAgICAgICAgICAgICAgIDxyZGY6bGkgcmRmOnBhcnNlVHlwZT0iUmVzb3VyY2UiPgogICAgICAgICAgICAgICAgICA8c3RFdnQ6YWN0aW9uPmNvbnZlcnRlZDwvc3RFdnQ6YWN0aW9uPgogICAgICAgICAgICAgICAgICA8c3RFdnQ6cGFyYW1ldGVycz5mcm9tIGltYWdlL3BuZyB0byBhcHBsaWNhdGlvbi92bmQuYWRvYmUucGhvdG9zaG9wPC9zdEV2dDpwYXJhbWV0ZXJzPgogICAgICAgICAgICAgICA8L3JkZjpsaT4KICAgICAgICAgICAgICAgPHJkZjpsaSByZGY6cGFyc2VUeXBlPSJSZXNvdXJjZSI+CiAgICAgICAgICAgICAgICAgIDxzdEV2dDphY3Rpb24+c2F2ZWQ8L3N0RXZ0OmFjdGlvbj4KICAgICAgICAgICAgICAgICAgPHN0RXZ0Omluc3RhbmNlSUQ+eG1wLmlpZDpGMjEwRTIyQzEzMjA2ODExODIyQUEwNjcyQ0Y4NjgyMzwvc3RFdnQ6aW5zdGFuY2VJRD4KICAgICAgICAgICAgICAgICAgPHN0RXZ0OndoZW4+MjAxNS0xMS0yMVQxMjozMTozNCswNTozMDwvc3RFdnQ6d2hlbj4KICAgICAgICAgICAgICAgICAgPHN0RXZ0OmNoYW5nZWQ+Lzwvc3RFdnQ6Y2hhbmdlZD4KICAgICAgICAgICAgICAgPC9yZGY6bGk+CiAgICAgICAgICAgICAgIDxyZGY6bGkgcmRmOnBhcnNlVHlwZT0iUmVzb3VyY2UiPgogICAgICAgICAgICAgICAgICA8c3RFdnQ6YWN0aW9uPmNvbnZlcnRlZDwvc3RFdnQ6YWN0aW9uPgogICAgICAgICAgICAgICAgICA8c3RFdnQ6cGFyYW1ldGVycz5mcm9tIGltYWdlL3BuZyB0byBhcHBsaWNhdGlvbi92bmQuYWRvYmUucGhvdG9zaG9wPC9zdEV2dDpwYXJhbWV0ZXJzPgogICAgICAgICAgICAgICA8L3JkZjpsaT4KICAgICAgICAgICAgICAgPHJkZjpsaSByZGY6cGFyc2VUeXBlPSJSZXNvdXJjZSI+CiAgICAgICAgICAgICAgICAgIDxzdEV2dDphY3Rpb24+c2F2ZWQ8L3N0RXZ0OmFjdGlvbj4KICAgICAgICAgICAgICAgICAgPHN0RXZ0Omluc3RhbmNlSUQ+eG1wLmlpZDpGMzEwRTIyQzEzMjA2ODExODIyQUEwNjcyQ0Y4NjgyMzwvc3RFdnQ6aW5zdGFuY2VJRD4KICAgICAgICAgICAgICAgICAgPHN0RXZ0OndoZW4+MjAxNS0xMS0yMVQxMjozMTozNCswNTozMDwvc3RFdnQ6d2hlbj4KICAgICAgICAgICAgICAgICAgPHN0RXZ0OmNoYW5nZWQ+Lzwvc3RFdnQ6Y2hhbmdlZD4KICAgICAgICAgICAgICAgPC9yZGY6bGk+CiAgICAgICAgICAgICAgIDxyZGY6bGkgcmRmOnBhcnNlVHlwZT0iUmVzb3VyY2UiPgogICAgICAgICAgICAgICAgICA8c3RFdnQ6YWN0aW9uPnNhdmVkPC9zdEV2dDphY3Rpb24+CiAgICAgICAgICAgICAgICAgIDxzdEV2dDppbnN0YW5jZUlEPnhtcC5paWQ6ZTM5OTZmYmItZTgwMS00N2Y1LTg5YjgtNTUwZjhhOTg1ODMwPC9zdEV2dDppbnN0YW5jZUlEPgogICAgICAgICAgICAgICAgICA8c3RFdnQ6d2hlbj4yMDE1LTExLTIxVDEyOjQwOjAxKzA1OjMwPC9zdEV2dDp3aGVuPgogICAgICAgICAgICAgICAgICA8c3RFdnQ6c29mdHdhcmVBZ2VudD5BZG9iZSBQaG90b3Nob3AgQ0MgMjAxNCAoTWFjaW50b3NoKTwvc3RFdnQ6c29mdHdhcmVBZ2VudD4KICAgICAgICAgICAgICAgICAgPHN0RXZ0OmNoYW5nZWQ+Lzwvc3RFdnQ6Y2hhbmdlZD4KICAgICAgICAgICAgICAgPC9yZGY6bGk+CiAgICAgICAgICAgICAgIDxyZGY6bGkgcmRmOnBhcnNlVHlwZT0iUmVzb3VyY2UiPgogICAgICAgICAgICAgICAgICA8c3RFdnQ6YWN0aW9uPmNvbnZlcnRlZDwvc3RFdnQ6YWN0aW9uPgogICAgICAgICAgICAgICAgICA8c3RFdnQ6cGFyYW1ldGVycz5mcm9tIGFwcGxpY2F0aW9uL3ZuZC5hZG9iZS5waG90b3Nob3AgdG8gaW1hZ2UvcG5nPC9zdEV2dDpwYXJhbWV0ZXJzPgogICAgICAgICAgICAgICA8L3JkZjpsaT4KICAgICAgICAgICAgICAgPHJkZjpsaSByZGY6cGFyc2VUeXBlPSJSZXNvdXJjZSI+CiAgICAgICAgICAgICAgICAgIDxzdEV2dDphY3Rpb24+ZGVyaXZlZDwvc3RFdnQ6YWN0aW9uPgogICAgICAgICAgICAgICAgICA8c3RFdnQ6cGFyYW1ldGVycz5jb252ZXJ0ZWQgZnJvbSBhcHBsaWNhdGlvbi92bmQuYWRvYmUucGhvdG9zaG9wIHRvIGltYWdlL3BuZzwvc3RFdnQ6cGFyYW1ldGVycz4KICAgICAgICAgICAgICAgPC9yZGY6bGk+CiAgICAgICAgICAgICAgIDxyZGY6bGkgcmRmOnBhcnNlVHlwZT0iUmVzb3VyY2UiPgogICAgICAgICAgICAgICAgICA8c3RFdnQ6YWN0aW9uPnNhdmVkPC9zdEV2dDphY3Rpb24+CiAgICAgICAgICAgICAgICAgIDxzdEV2dDppbnN0YW5jZUlEPnhtcC5paWQ6MTNjNDEyMmEtM2RmMS00Mzg4LTgzMzctZDk5ZTI2MjZmOGQzPC9zdEV2dDppbnN0YW5jZUlEPgogICAgICAgICAgICAgICAgICA8c3RFdnQ6d2hlbj4yMDE1LTExLTIxVDEyOjQwOjAxKzA1OjMwPC9zdEV2dDp3aGVuPgogICAgICAgICAgICAgICAgICA8c3RFdnQ6c29mdHdhcmVBZ2VudD5BZG9iZSBQaG90b3Nob3AgQ0MgMjAxNCAoTWFjaW50b3NoKTwvc3RFdnQ6c29mdHdhcmVBZ2VudD4KICAgICAgICAgICAgICAgICAgPHN0RXZ0OmNoYW5nZWQ+Lzwvc3RFdnQ6Y2hhbmdlZD4KICAgICAgICAgICAgICAgPC9yZGY6bGk+CiAgICAgICAgICAgIDwvcmRmOlNlcT4KICAgICAgICAgPC94bXBNTTpIaXN0b3J5PgogICAgICAgICA8eG1wTU06RGVyaXZlZEZyb20gcmRmOnBhcnNlVHlwZT0iUmVzb3VyY2UiPgogICAgICAgICAgICA8c3RSZWY6aW5zdGFuY2VJRD54bXAuaWlkOmUzOTk2ZmJiLWU4MDEtNDdmNS04OWI4LTU1MGY4YTk4NTgzMDwvc3RSZWY6aW5zdGFuY2VJRD4KICAgICAgICAgICAgPHN0UmVmOmRvY3VtZW50SUQ+eG1wLmRpZDpGMjEwRTIyQzEzMjA2ODExODIyQUEwNjcyQ0Y4NjgyMzwvc3RSZWY6ZG9jdW1lbnRJRD4KICAgICAgICAgICAgPHN0UmVmOm9yaWdpbmFsRG9jdW1lbnRJRD54bXAuZGlkOkYyMTBFMjJDMTMyMDY4MTE4MjJBQTA2NzJDRjg2ODIzPC9zdFJlZjpvcmlnaW5hbERvY3VtZW50SUQ+CiAgICAgICAgIDwveG1wTU06RGVyaXZlZEZyb20+CiAgICAgICAgIDx4bXBNTTpEb2N1bWVudElEPmFkb2JlOmRvY2lkOnBob3Rvc2hvcDo0ZTZiYTI5Mi1kMGFkLTExNzgtOGU3OS04ZjUxMjZiM2FlYjU8L3htcE1NOkRvY3VtZW50SUQ+CiAgICAgICAgIDx4bXBNTTpJbnN0YW5jZUlEPnhtcC5paWQ6MTNjNDEyMmEtM2RmMS00Mzg4LTgzMzctZDk5ZTI2MjZmOGQzPC94bXBNTTpJbnN0YW5jZUlEPgogICAgICAgICA8eG1wTU06T3JpZ2luYWxEb2N1bWVudElEPnhtcC5kaWQ6RjIxMEUyMkMxMzIwNjgxMTgyMkFBMDY3MkNGODY4MjM8L3htcE1NOk9yaWdpbmFsRG9jdW1lbnRJRD4KICAgICAgICAgPHBob3Rvc2hvcDpDb2xvck1vZGU+MzwvcGhvdG9zaG9wOkNvbG9yTW9kZT4KICAgICAgICAgPHRpZmY6T3JpZW50YXRpb24+MTwvdGlmZjpPcmllbnRhdGlvbj4KICAgICAgICAgPHRpZmY6WFJlc29sdXRpb24+NzIwMDAwLzEwMDAwPC90aWZmOlhSZXNvbHV0aW9uPgogICAgICAgICA8dGlmZjpZUmVzb2x1dGlvbj43MjAwMDAvMTAwMDA8L3RpZmY6WVJlc29sdXRpb24+CiAgICAgICAgIDx0aWZmOlJlc29sdXRpb25Vbml0PjI8L3RpZmY6UmVzb2x1dGlvblVuaXQ+CiAgICAgICAgIDxleGlmOkNvbG9yU3BhY2U+NjU1MzU8L2V4aWY6Q29sb3JTcGFjZT4KICAgICAgICAgPGV4aWY6UGl4ZWxYRGltZW5zaW9uPjI1NjwvZXhpZjpQaXhlbFhEaW1lbnNpb24+CiAgICAgICAgIDxleGlmOlBpeGVsWURpbWVuc2lvbj4yNTY8L2V4aWY6UGl4ZWxZRGltZW5zaW9uPgogICAgICA8L3JkZjpEZXNjcmlwdGlvbj4KICAgPC9yZGY6UkRGPgo8L3g6eG1wbWV0YT4KICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAKICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgIAogICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgICAgCiAgICAgICAgICAgICAgICAgICAgICAgICAgICAKPD94cGFja2V0IGVuZD0idyI/PmeXOsMAAAAgY0hSTQAAeiUAAICDAAD5/wAAgOkAAHUwAADqYAAAOpgAABdvkl/FRgAADgxJREFUeNrs3XmsHVUBx/Hvw5ZCSxcKlLII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";*/
        await getBase64ImageFromUrl(src)
            .then(result => svg1.getElementsByTagName('image')[i].setAttribute('xlink:href', result))
            .catch(err => console.error(err));




    }




    var s = new XMLSerializer();
    var str = serializeXmlNode(svg1);// s.serializeToString(svg);

    str = str.replace("[Not supported by viewer]", "");


    //var canvas1 = document.getElementById("canvasPdf");
    //canvas1.width = wid;
    //canvas1.height = hei;



    //const ctx = canvas1.getContext('2d');

    var svgImage = new Image();
    svgImage.src = 'data:image/svg+xml;charset=utf-8,' + encodeURIComponent(str);
    svgImage.onload = function () {
        debugger;
        // create a canvas or get it from the page
        // create a canvas or get it from the page
        var canvas = document.createElement("canvas");
        // set the resolution (number of pixels)
        canvas.width = wid + 2000; canvas.height = hei + 2000;


        canvas.width = canvas.width * devicePixelRatio;
        canvas.height = canvas.height * devicePixelRatio;



        // set the display size
        canvas.style.width = wid + "px"; canvas.style.height = hei + "px";
        // get the rendering context


        var context = canvas.getContext("2d");

        context.fillStyle = "#FFFFFF";
        context.fillRect(0, 0, canvas.width, canvas.height);

        var scale = Math.min(canvas.width / wid, canvas.height / hei);

        if (scale > 6) {
            scale = 3;
        }
        // get the top left position of the image
        var x = (canvas.width / 2) - (wid / 2) * scale;
        var y = (canvas.height / 2) - (hei / 2) * scale;

        context.setTransform(scale, 0, 0, scale, 0, 0);

        context.scale(devicePixelRatio, devicePixelRatio);



        context.drawImage(svgImage, 0, 0, wid, hei);




        var img = new Image();
        img.src = $(canvas).get(0).toDataURL('image/jpeg', 1.0);


        $(canvas).remove();


        img.onload = function () {


            img.width = wid;
            img.height = hei;

            img.style.imageRendering = "-moz-crisp-edges";


            $(img).resizeAndCrop();



            var link = document.createElement('a');
            link.download = name;
            link.href = img.src;
            link.click();
            link.remove();







        }
        //if (alreadydone == true) {

        //        debugger;
        //        var link = document.createElement('a');
        //        link.download = name;
        //        link.href = img1.src;
        //        link.click();
        //        link.remove();
        //        return;

        //}











    }







}

/**
 * Hook for getting the export format. Returns null for the default
 * intermediate XML export format or a function that returns the
 * parameter and value to be used in the request in the form
 * key=value, where value should be URL encoded.
 */
ExportDialog.saveLocalFile = function (editorUi, data, filename, format) {
    if (data.length < MAX_REQUEST_SIZE) {
        editorUi.hideDialog();
        var req = new mxXmlRequest(SAVE_URL, 'xml=' + encodeURIComponent(data) + '&filename=' +
            encodeURIComponent(filename) + '&format=' + format);
        req.simulate(document, '_blank');
    }
    else {
        mxUtils.alert(mxResources.get('drawingTooLarge'));
        mxUtils.popup(xml);
    }
};

/**
 * Constructs a new metadata dialog.
 */
var EditDataDialog = function (ui, cell) {
    var div = document.createElement('div');
    var graph = ui.editor.graph;

    var value = graph.getModel().getValue(cell);

    // Converts the value to an XML node
    if (!mxUtils.isNode(value)) {
        var doc = mxUtils.createXmlDocument();
        var obj = doc.createElement('object');
        obj.setAttribute('label', value || '');
        value = obj;
    }

    var meta = {};

    try {
        var temp = mxUtils.getValue(ui.editor.graph.getCurrentCellStyle(cell), 'metaData', null);

        if (temp != null) {
            meta = JSON.parse(temp);
        }
    }
    catch (e) {
        // ignore
    }

    // Creates the dialog contents
    var form = new mxForm('properties');
    form.table.style.width = '100%';

    var attrs = value.attributes;
    var names = [];
    var texts = [];
    var count = 0;

    var id = (EditDataDialog.getDisplayIdForCell != null) ?
        EditDataDialog.getDisplayIdForCell(ui, cell) : null;

    var addRemoveButton = function (text, name) {
        var wrapper = document.createElement('div');
        wrapper.style.position = 'relative';
        wrapper.style.paddingRight = '20px';
        wrapper.style.boxSizing = 'border-box';
        wrapper.style.width = '100%';

        var removeAttr = document.createElement('a');
        var img = mxUtils.createImage(Dialog.prototype.closeImage);
        img.style.height = '9px';
        img.style.fontSize = '9px';
        img.style.marginBottom = (mxClient.IS_IE11) ? '-1px' : '5px';

        removeAttr.className = 'geButton';
        removeAttr.setAttribute('title', mxResources.get('delete'));
        removeAttr.style.position = 'absolute';
        removeAttr.style.top = '4px';
        removeAttr.style.right = '0px';
        removeAttr.style.margin = '0px';
        removeAttr.style.width = '9px';
        removeAttr.style.height = '9px';
        removeAttr.style.cursor = 'pointer';
        removeAttr.appendChild(img);

        var removeAttrFn = (function (name) {
            return function () {
                var count = 0;

                for (var j = 0; j < names.length; j++) {
                    if (names[j] == name) {
                        texts[j] = null;
                        form.table.deleteRow(count + ((id != null) ? 1 : 0));

                        break;
                    }

                    if (texts[j] != null) {
                        count++;
                    }
                }
            };
        })(name);

        mxEvent.addListener(removeAttr, 'click', removeAttrFn);

        var parent = text.parentNode;
        wrapper.appendChild(text);
        wrapper.appendChild(removeAttr);
        parent.appendChild(wrapper);
    };

    var addTextArea = function (index, name, value) {
        names[index] = name;
        texts[index] = form.addTextarea(names[count] + ':', value, 2);
        texts[index].style.width = '100%';

        if (value.indexOf('\n') > 0) {
            texts[index].setAttribute('rows', '2');
        }

        addRemoveButton(texts[index], name);

        if (meta[name] != null && meta[name].editable == false) {
            texts[index].setAttribute('disabled', 'disabled');
        }
    };

    var temp = [];
    var isLayer = graph.getModel().getParent(cell) == graph.getModel().getRoot();

    for (var i = 0; i < attrs.length; i++) {
        if ((isLayer || attrs[i].nodeName != 'label') && attrs[i].nodeName != 'placeholders') {
            temp.push({ name: attrs[i].nodeName, value: attrs[i].nodeValue });
        }
    }

    // Sorts by name
    temp.sort(function (a, b) {
        if (a.name < b.name) {
            return -1;
        }
        else if (a.name > b.name) {
            return 1;
        }
        else {
            return 0;
        }
    });

    if (id != null) {
        var text = document.createElement('div');
        text.style.width = '100%';
        text.style.fontSize = '11px';
        text.style.textAlign = 'center';
        mxUtils.write(text, id);

        var idInput = form.addField(mxResources.get('id') + ':', text);

        mxEvent.addListener(text, 'dblclick', function (evt) {
            if (mxEvent.isShiftDown(evt)) {
                var dlg = new FilenameDialog(ui, id, mxResources.get('apply'), mxUtils.bind(this, function (value) {
                    if (value != null && value.length > 0 && value != id) {
                        if (graph.getModel().getCell(value) == null) {
                            graph.getModel().cellRemoved(cell);
                            cell.setId(value);
                            id = value;
                            idInput.innerHTML = mxUtils.htmlEntities(value);
                            graph.getModel().cellAdded(cell);
                        }
                        else {
                            ui.handleError({ message: mxResources.get('alreadyExst', [value]) });
                        }
                    }
                }), mxResources.get('id'));
                ui.showDialog(dlg.container, 300, 80, true, true);
                dlg.init();
            }
        });

        text.setAttribute('title', 'Shift+Double Click to Edit ID');
    }

    for (var i = 0; i < temp.length; i++) {
        addTextArea(count, temp[i].name, temp[i].value);
        count++;
    }

    var top = document.createElement('div');
    top.style.position = 'absolute';
    top.style.top = '30px';
    top.style.left = '30px';
    top.style.right = '30px';
    top.style.bottom = '80px';
    top.style.overflowY = 'auto';

    top.appendChild(form.table);

    var newProp = document.createElement('div');
    newProp.style.boxSizing = 'border-box';
    newProp.style.paddingRight = '160px';
    newProp.style.whiteSpace = 'nowrap';
    newProp.style.marginTop = '6px';
    newProp.style.width = '100%';

    var nameInput = document.createElement('input');
    nameInput.setAttribute('placeholder', mxResources.get('enterPropertyName'));
    nameInput.setAttribute('type', 'text');
    nameInput.setAttribute('size', (mxClient.IS_IE || mxClient.IS_IE11) ? '36' : '40');
    nameInput.style.boxSizing = 'border-box';
    nameInput.style.marginLeft = '2px';
    nameInput.style.width = '100%';

    newProp.appendChild(nameInput);
    top.appendChild(newProp);
    div.appendChild(top);

    var addBtn = mxUtils.button(mxResources.get('addProperty'), function () {
        var name = nameInput.value;

        // Avoid ':' in attribute names which seems to be valid in Chrome
        if (name.length > 0 && name != 'label' && name != 'placeholders' && name.indexOf(':') < 0) {
            try {
                var idx = mxUtils.indexOf(names, name);

                if (idx >= 0 && texts[idx] != null) {
                    texts[idx].focus();
                }
                else {
                    // Checks if the name is valid
                    var clone = value.cloneNode(false);
                    clone.setAttribute(name, '');

                    if (idx >= 0) {
                        names.splice(idx, 1);
                        texts.splice(idx, 1);
                    }

                    names.push(name);
                    var text = form.addTextarea(name + ':', '', 2);
                    text.style.width = '100%';
                    texts.push(text);
                    addRemoveButton(text, name);

                    text.focus();
                }

                addBtn.setAttribute('disabled', 'disabled');
                nameInput.value = '';
            }
            catch (e) {
                mxUtils.alert(e);
            }
        }
        else {
            mxUtils.alert(mxResources.get('invalidName'));
        }
    });

    mxEvent.addListener(nameInput, 'keypress', function (e) {
        if (e.keyCode == 13) {
            addBtn.click();
        }
    });

    this.init = function () {
        if (texts.length > 0) {
            texts[0].focus();
        }
        else {
            nameInput.focus();
        }
    };

    addBtn.setAttribute('title', mxResources.get('addProperty'));
    addBtn.setAttribute('disabled', 'disabled');
    addBtn.style.textOverflow = 'ellipsis';
    addBtn.style.position = 'absolute';
    addBtn.style.overflow = 'hidden';
    addBtn.style.width = '144px';
    addBtn.style.right = '0px';
    addBtn.className = 'geBtn';
    newProp.appendChild(addBtn);

    var cancelBtn = mxUtils.button(mxResources.get('cancel'), function () {
        ui.hideDialog.apply(ui, arguments);
    });


    cancelBtn.setAttribute('title', 'Escape');
    cancelBtn.className = 'geBtn';

    var applyBtn = mxUtils.button(mxResources.get('apply'), function () {
        try {
            ui.hideDialog.apply(ui, arguments);

            // Clones and updates the value
            value = value.cloneNode(true);
            var removeLabel = false;

            for (var i = 0; i < names.length; i++) {
                if (texts[i] == null) {
                    value.removeAttribute(names[i]);
                }
                else {
                    value.setAttribute(names[i], texts[i].value);
                    removeLabel = removeLabel || (names[i] == 'placeholder' &&
                        value.getAttribute('placeholders') == '1');
                }
            }

            // Removes label if placeholder is assigned
            if (removeLabel) {
                value.removeAttribute('label');
            }

            // Updates the value of the cell (undoable)
            graph.getModel().setValue(cell, value);
        }
        catch (e) {
            mxUtils.alert(e);
        }
    });

    applyBtn.setAttribute('title', 'Ctrl+Enter');
    applyBtn.className = 'geBtn gePrimaryBtn';

    mxEvent.addListener(div, 'keypress', function (e) {
        if (e.keyCode == 13 && mxEvent.isControlDown(e)) {
            applyBtn.click();
        }
    });

    function updateAddBtn() {
        if (nameInput.value.length > 0) {
            addBtn.removeAttribute('disabled');
        }
        else {
            addBtn.setAttribute('disabled', 'disabled');
        }
    };

    mxEvent.addListener(nameInput, 'keyup', updateAddBtn);

    // Catches all changes that don't fire a keyup (such as paste via mouse)
    mxEvent.addListener(nameInput, 'change', updateAddBtn);

    var buttons = document.createElement('div');
    buttons.style.cssText = 'position:absolute;left:30px;right:30px;text-align:right;bottom:30px;height:40px;'

    if (ui.editor.graph.getModel().isVertex(cell) || ui.editor.graph.getModel().isEdge(cell)) {
        var replace = document.createElement('span');
        replace.style.marginRight = '10px';
        var input = document.createElement('input');
        input.setAttribute('type', 'checkbox');
        input.style.marginRight = '6px';

        if (value.getAttribute('placeholders') == '1') {
            input.setAttribute('checked', 'checked');
            input.defaultChecked = true;
        }

        mxEvent.addListener(input, 'click', function () {
            if (value.getAttribute('placeholders') == '1') {
                value.removeAttribute('placeholders');
            }
            else {
                value.setAttribute('placeholders', '1');
            }
        });

        replace.appendChild(input);
        mxUtils.write(replace, mxResources.get('placeholders'));

        if (EditDataDialog.placeholderHelpLink != null) {
            var link = document.createElement('a');
            link.setAttribute('href', EditDataDialog.placeholderHelpLink);
            link.setAttribute('title', mxResources.get('help'));
            link.setAttribute('target', '_blank');
            link.style.marginLeft = '8px';
            link.style.cursor = 'help';

            var icon = document.createElement('img');
            mxUtils.setOpacity(icon, 50);
            icon.style.height = '16px';
            icon.style.width = '16px';
            icon.setAttribute('border', '0');
            icon.setAttribute('valign', 'middle');
            icon.style.marginTop = (mxClient.IS_IE11) ? '0px' : '-4px';
            icon.setAttribute('src', Editor.helpImage);
            link.appendChild(icon);

            replace.appendChild(link);
        }

        buttons.appendChild(replace);
    }

    if (ui.editor.cancelFirst) {
        buttons.appendChild(cancelBtn);
        buttons.appendChild(applyBtn);
    }
    else {
        buttons.appendChild(applyBtn);
        buttons.appendChild(cancelBtn);
    }

    div.appendChild(buttons);
    this.container = div;
};

/**
 * Optional help link.
 */
EditDataDialog.getDisplayIdForCell = function (ui, cell) {
    var id = null;

    if (ui.editor.graph.getModel().getParent(cell) != null) {
        id = cell.getId();
    }

    return id;
};

/**
 * Optional help link.
 */
EditDataDialog.placeholderHelpLink = null;

/**
 * Constructs a new link dialog.
 */
var LinkDialog = function (editorUi, initialValue, btnLabel, fn) {
    var div = document.createElement('div');
    mxUtils.write(div, mxResources.get('editLink') + ':');

    var inner = document.createElement('div');
    inner.className = 'geTitle';
    inner.style.backgroundColor = 'transparent';
    inner.style.borderColor = 'transparent';
    inner.style.whiteSpace = 'nowrap';
    inner.style.textOverflow = 'clip';
    inner.style.cursor = 'default';
    inner.style.paddingRight = '20px';

    var linkInput = document.createElement('input');
    linkInput.setAttribute('value', initialValue);
    linkInput.setAttribute('placeholder', 'http://www.example.com/');
    linkInput.setAttribute('type', 'text');
    linkInput.style.marginTop = '6px';
    linkInput.style.width = '400px';
    linkInput.style.backgroundImage = 'url(\'' + Dialog.prototype.clearImage + '\')';
    linkInput.style.backgroundRepeat = 'no-repeat';
    linkInput.style.backgroundPosition = '100% 50%';
    linkInput.style.paddingRight = '14px';

    var cross = document.createElement('div');
    cross.setAttribute('title', mxResources.get('reset'));
    cross.style.position = 'relative';
    cross.style.left = '-16px';
    cross.style.width = '12px';
    cross.style.height = '14px';
    cross.style.cursor = 'pointer';

    // Workaround for inline-block not supported in IE
    cross.style.display = 'inline-block';
    cross.style.top = '3px';

    // Needed to block event transparency in IE
    cross.style.background = 'url(' + IMAGE_PATH + '/transparent.gif)';

    mxEvent.addListener(cross, 'click', function () {
        linkInput.value = '';
        linkInput.focus();
    });

    inner.appendChild(linkInput);
    inner.appendChild(cross);
    div.appendChild(inner);

    this.init = function () {
        linkInput.focus();

        if (mxClient.IS_GC || mxClient.IS_FF || document.documentMode >= 5) {
            linkInput.select();
        }
        else {
            document.execCommand('selectAll', false, null);
        }
    };

    var btns = document.createElement('div');
    btns.style.marginTop = '18px';
    btns.style.textAlign = 'right';

    mxEvent.addListener(linkInput, 'keypress', function (e) {
        if (e.keyCode == 13) {
            editorUi.hideDialog();
            fn(linkInput.value);
        }
    });

    var cancelBtn = mxUtils.button(mxResources.get('cancel'), function () {
        editorUi.hideDialog();
    });
    cancelBtn.className = 'geBtn';

    if (editorUi.editor.cancelFirst) {
        btns.appendChild(cancelBtn);
    }

    var mainBtn = mxUtils.button(btnLabel, function () {
        editorUi.hideDialog();
        fn(linkInput.value);
    });
    mainBtn.className = 'geBtn gePrimaryBtn';
    btns.appendChild(mainBtn);

    if (!editorUi.editor.cancelFirst) {
        btns.appendChild(cancelBtn);
    }

    div.appendChild(btns);

    this.container = div;
};

/**
 * 
 */
var OutlineWindow = function (editorUi, x, y, w, h) {
    var graph = editorUi.editor.graph;

    var div = document.createElement('div');
    div.style.position = 'absolute';
    div.style.width = '100%';
    div.style.height = '100%';
    div.style.overflow = 'hidden';

    this.window = new mxWindow(mxResources.get('outline'), div, x, y, w, h, true, true);
    this.window.minimumSize = new mxRectangle(0, 0, 80, 80);
    this.window.destroyOnClose = false;
    this.window.setMaximizable(false);
    this.window.setResizable(true);
    this.window.setClosable(true);
    this.window.setVisible(true);

    this.window.setLocation = function (x, y) {
        var iw = window.innerWidth || document.body.clientWidth || document.documentElement.clientWidth;
        var ih = window.innerHeight || document.body.clientHeight || document.documentElement.clientHeight;

        x = Math.max(0, Math.min(x, iw - this.table.clientWidth));
        y = Math.max(0, Math.min(y, ih - this.table.clientHeight - ((urlParams['sketch'] == '1') ? 3 : 48)));

        if (this.getX() != x || this.getY() != y) {
            mxWindow.prototype.setLocation.apply(this, arguments);
        }
    };

    var resizeListener = mxUtils.bind(this, function () {
        var x = this.window.getX();
        var y = this.window.getY();

        this.window.setLocation(x, y);
    });

    mxEvent.addListener(window, 'resize', resizeListener);

    var outline = editorUi.createOutline(this.window);

    this.destroy = function () {
        mxEvent.removeListener(window, 'resize', resizeListener);
        this.window.destroy();
        outline.destroy();
    }

    this.window.addListener(mxEvent.SHOW, mxUtils.bind(this, function () {
        this.window.fit();
        outline.setSuspended(false);
    }));

    this.window.addListener(mxEvent.HIDE, mxUtils.bind(this, function () {
        outline.setSuspended(true);
    }));

    this.window.addListener(mxEvent.NORMALIZE, mxUtils.bind(this, function () {
        outline.setSuspended(false);
    }));

    this.window.addListener(mxEvent.MINIMIZE, mxUtils.bind(this, function () {
        outline.setSuspended(true);
    }));

    outline.init(div);

    var zoomInAction = editorUi.actions.get('zoomIn');
    var zoomOutAction = editorUi.actions.get('zoomOut');

    mxEvent.addMouseWheelListener(function (evt, up) {
        var outlineWheel = false;
        var source = mxEvent.getSource(evt);

        while (source != null) {
            if (source == outline.svg) {
                outlineWheel = true;
                break;
            }

            source = source.parentNode;
        }

        if (outlineWheel) {
            var factor = graph.zoomFactor;

            // Slower zoom for pinch gesture on trackpad
            if (evt.deltaY != null && Math.round(evt.deltaY) != evt.deltaY) {
                factor = 1 + (Math.abs(evt.deltaY) / 20) * (factor - 1);
            }

            graph.lazyZoom(up, null, null, factor);
            mxEvent.consume(evt);
        }
    });
};

/**
 * 
 */
var LayersWindow = function (editorUi, x, y, w, h) {
    var graph = editorUi.editor.graph;

    var div = document.createElement('div');
    div.style.userSelect = 'none';
    div.style.background = (!Editor.isDarkMode()) ? '#fff' : Dialog.backdropColor;
    div.style.border = '1px solid whiteSmoke';
    div.style.height = '100%';
    div.style.marginBottom = '10px';
    div.style.overflow = 'auto';

    var tbarHeight = (!EditorUi.compactUi) ? '30px' : '26px';

    var listDiv = document.createElement('div')
    listDiv.style.backgroundColor = (!Editor.isDarkMode()) ? '#fff' : Dialog.backdropColor;
    listDiv.style.position = 'absolute';
    listDiv.style.overflow = 'auto';
    listDiv.style.left = '0px';
    listDiv.style.right = '0px';
    listDiv.style.top = '0px';
    listDiv.style.bottom = (parseInt(tbarHeight) + 7) + 'px';
    div.appendChild(listDiv);

    var dragSource = null;
    var dropIndex = null;

    mxEvent.addListener(div, 'dragover', function (evt) {
        evt.dataTransfer.dropEffect = 'move';
        dropIndex = 0;
        evt.stopPropagation();
        evt.preventDefault();
    });

    // Workaround for "no element found" error in FF
    mxEvent.addListener(div, 'drop', function (evt) {
        evt.stopPropagation();
        evt.preventDefault();
    });

    var layerCount = null;
    var selectionLayer = null;
    var ldiv = document.createElement('div');

    ldiv.className = 'geToolbarContainer';
    ldiv.style.position = 'absolute';
    ldiv.style.bottom = '0px';
    ldiv.style.left = '0px';
    ldiv.style.right = '0px';
    ldiv.style.height = tbarHeight;
    ldiv.style.overflow = 'hidden';
    ldiv.style.padding = (!EditorUi.compactUi) ? '1px' : '4px 0px 3px 0px';
    ldiv.style.backgroundColor = (!Editor.isDarkMode()) ? 'whiteSmoke' : Dialog.backdropColor;
    ldiv.style.borderWidth = '1px 0px 0px 0px';
    ldiv.style.borderColor = '#c3c3c3';
    ldiv.style.borderStyle = 'solid';
    ldiv.style.display = 'block';
    ldiv.style.whiteSpace = 'nowrap';

    var link = document.createElement('a');
    link.className = 'geButton';

    var removeLink = link.cloneNode(false);
    var img = document.createElement('img');
    img.setAttribute('border', '0');
    img.setAttribute('width', '22');
    img.setAttribute('src', Editor.trashImage);
    img.style.opacity = '0.9';

    if (Editor.isDarkMode()) {
        img.style.filter = 'invert(100%)';
    }

    removeLink.appendChild(img);

    mxEvent.addListener(removeLink, 'click', function (evt) {
        if (graph.isEnabled()) {
            graph.model.beginUpdate();
            try {
                var index = graph.model.root.getIndex(selectionLayer);
                graph.removeCells([selectionLayer], false);

                // Creates default layer if no layer exists
                if (graph.model.getChildCount(graph.model.root) == 0) {
                    graph.model.add(graph.model.root, new mxCell());
                    graph.setDefaultParent(null);
                }
                else if (index > 0 && index <= graph.model.getChildCount(graph.model.root)) {
                    graph.setDefaultParent(graph.model.getChildAt(graph.model.root, index - 1));
                }
                else {
                    graph.setDefaultParent(null);
                }
            }
            finally {
                graph.model.endUpdate();
            }
        }

        mxEvent.consume(evt);
    });

    if (!graph.isEnabled()) {
        removeLink.className = 'geButton mxDisabled';
    }

    ldiv.appendChild(removeLink);

    var insertLink = link.cloneNode();
    insertLink.setAttribute('title', mxUtils.trim(mxResources.get('moveSelectionTo', ['...'])));

    img = img.cloneNode(false);
    img.setAttribute('src', Editor.verticalDotsImage);
    insertLink.appendChild(img);

    mxEvent.addListener(insertLink, 'click', function (evt) {
        if (graph.isEnabled() && !graph.isSelectionEmpty()) {
            var offset = mxUtils.getOffset(insertLink);

            editorUi.showPopupMenu(mxUtils.bind(this, function (menu, parent) {
                for (var i = layerCount - 1; i >= 0; i--) {
                    (mxUtils.bind(this, function (child) {
                        var item = menu.addItem(graph.convertValueToString(child) ||
                            mxResources.get('background'), null, mxUtils.bind(this, function () {
                                graph.moveCells(graph.getSelectionCells(), 0, 0, false, child);
                            }), parent);

                        if (graph.getSelectionCount() == 1 && graph.model.isAncestor(child, graph.getSelectionCell())) {
                            menu.addCheckmark(item, Editor.checkmarkImage);
                        }

                    }))(graph.model.getChildAt(graph.model.root, i));
                }
            }), offset.x, offset.y + insertLink.offsetHeight, evt);
        }
    });

    ldiv.appendChild(insertLink);

    var dataLink = link.cloneNode(false);
    dataLink.setAttribute('title', mxResources.get('editData'));

    img = img.cloneNode(false);
    img.setAttribute('src', Editor.editImage);
    dataLink.appendChild(img);

    mxEvent.addListener(dataLink, 'click', function (evt) {
        if (graph.isEnabled()) {
            editorUi.showDataDialog(selectionLayer);
        }

        mxEvent.consume(evt);
    });

    if (!graph.isEnabled()) {
        dataLink.className = 'geButton mxDisabled';
    }

    ldiv.appendChild(dataLink);

    function renameLayer(layer) {
        if (graph.isEnabled() && layer != null) {
            var label = graph.convertValueToString(layer);
            var dlg = new FilenameDialog(editorUi, label || mxResources.get('background'), mxResources.get('rename'), mxUtils.bind(this, function (newValue) {
                if (newValue != null) {
                    graph.cellLabelChanged(layer, newValue);
                }
            }), mxResources.get('enterName'));
            editorUi.showDialog(dlg.container, 300, 100, true, true);
            dlg.init();
        }
    };

    var duplicateLink = link.cloneNode(false);
    duplicateLink.setAttribute('title', mxResources.get('duplicate'));

    img = img.cloneNode(false);
    img.setAttribute('src', Editor.duplicateImage);
    duplicateLink.appendChild(img);

    mxEvent.addListener(duplicateLink, 'click', function (evt) {
        if (graph.isEnabled()) {
            var newCell = null;
            graph.model.beginUpdate();
            try {
                newCell = graph.cloneCell(selectionLayer);
                graph.cellLabelChanged(newCell, mxResources.get('untitledLayer'));
                newCell.setVisible(true);
                newCell = graph.addCell(newCell, graph.model.root);
                graph.setDefaultParent(newCell);
            }
            finally {
                graph.model.endUpdate();
            }

            if (newCell != null && !graph.isCellLocked(newCell)) {
                graph.selectAll(newCell);
            }
        }
    });

    if (!graph.isEnabled()) {
        duplicateLink.className = 'geButton mxDisabled';
    }

    ldiv.appendChild(duplicateLink);

    var addLink = link.cloneNode(false);
    addLink.setAttribute('title', mxResources.get('addLayer'));

    img = img.cloneNode(false);
    img.setAttribute('src', Editor.addImage);
    addLink.appendChild(img);

    mxEvent.addListener(addLink, 'click', function (evt) {
        if (graph.isEnabled()) {
            graph.model.beginUpdate();

            try {
                var cell = graph.addCell(new mxCell(mxResources.get('untitledLayer')), graph.model.root);
                graph.setDefaultParent(cell);
            }
            finally {
                graph.model.endUpdate();
            }
        }

        mxEvent.consume(evt);
    });

    if (!graph.isEnabled()) {
        addLink.className = 'geButton mxDisabled';
    }

    ldiv.appendChild(addLink);
    div.appendChild(ldiv);

    var layerDivs = new mxDictionary();

    var dot = document.createElement('span');
    dot.setAttribute('title', mxResources.get('selectionOnly'));
    dot.innerHTML = '&#8226;';
    dot.style.position = 'absolute';
    dot.style.fontWeight = 'bold';
    dot.style.fontSize = '16pt';
    dot.style.right = '2px';
    dot.style.top = '2px';

    function updateLayerDot() {
        var div = layerDivs.get(graph.getLayerForCells(graph.getSelectionCells()));

        if (div != null) {
            div.appendChild(dot);
        }
        else if (dot.parentNode != null) {
            dot.parentNode.removeChild(dot);
        }
    };

    function refresh() {
        layerCount = graph.model.getChildCount(graph.model.root)
        listDiv.innerText = '';
        layerDivs.clear();

        function addLayer(index, label, child, defaultParent) {
            var ldiv = document.createElement('div');
            ldiv.className = 'geToolbarContainer';
            layerDivs.put(child, ldiv);

            ldiv.style.overflow = 'hidden';
            ldiv.style.position = 'relative';
            ldiv.style.padding = '4px';
            ldiv.style.height = '22px';
            ldiv.style.display = 'block';
            ldiv.style.backgroundColor = (!Editor.isDarkMode()) ? 'whiteSmoke' : Dialog.backdropColor;
            ldiv.style.borderWidth = '0px 0px 1px 0px';
            ldiv.style.borderColor = '#c3c3c3';
            ldiv.style.borderStyle = 'solid';
            ldiv.style.whiteSpace = 'nowrap';
            ldiv.setAttribute('title', label);

            var left = document.createElement('div');
            left.style.display = 'inline-block';
            left.style.width = '100%';
            left.style.textOverflow = 'ellipsis';
            left.style.overflow = 'hidden';

            mxEvent.addListener(ldiv, 'dragover', function (evt) {
                evt.dataTransfer.dropEffect = 'move';
                dropIndex = index;
                evt.stopPropagation();
                evt.preventDefault();
            });

            mxEvent.addListener(ldiv, 'dragstart', function (evt) {
                dragSource = ldiv;

                // Workaround for no DnD on DIV in FF
                if (mxClient.IS_FF) {
                    // LATER: Check what triggers a parse as XML on this in FF after drop
                    evt.dataTransfer.setData('Text', '<layer/>');
                }
            });

            mxEvent.addListener(ldiv, 'dragend', function (evt) {
                if (dragSource != null && dropIndex != null) {
                    graph.addCell(child, graph.model.root, dropIndex);
                }

                dragSource = null;
                dropIndex = null;
                evt.stopPropagation();
                evt.preventDefault();
            });

            var inp = document.createElement('img');
            inp.setAttribute('draggable', 'false');
            inp.setAttribute('align', 'top');
            inp.setAttribute('border', '0');
            inp.style.width = '16px';
            inp.style.padding = '0px 6px 0 4px';
            inp.style.marginTop = '2px';
            inp.style.cursor = 'pointer';
            inp.setAttribute('title', mxResources.get(
                graph.model.isVisible(child) ?
                    'hide' : 'show'));

            if (graph.model.isVisible(child)) {
                inp.setAttribute('src', Editor.visibleImage);
                mxUtils.setOpacity(ldiv, 75);
            }
            else {
                inp.setAttribute('src', Editor.hiddenImage);
                mxUtils.setOpacity(ldiv, 25);
            }

            if (Editor.isDarkMode()) {
                inp.style.filter = 'invert(100%)';
            }

            left.appendChild(inp);

            mxEvent.addListener(inp, 'click', function (evt) {
                graph.model.setVisible(child, !graph.model.isVisible(child));
                mxEvent.consume(evt);
            });

            var btn = document.createElement('img');
            btn.setAttribute('draggable', 'false');
            btn.setAttribute('align', 'top');
            btn.setAttribute('border', '0');
            btn.style.width = '16px';
            btn.style.padding = '0px 6px 0 0';
            btn.style.marginTop = '2px';
            btn.setAttribute('title', mxResources.get('lockUnlock'));

            var style = graph.getCurrentCellStyle(child);

            if (mxUtils.getValue(style, 'locked', '0') == '1') {
                btn.setAttribute('src', Editor.lockedImage);
                mxUtils.setOpacity(btn, 75);
            }
            else {
                btn.setAttribute('src', Editor.unlockedImage);
                mxUtils.setOpacity(btn, 25);
            }

            if (Editor.isDarkMode()) {
                btn.style.filter = 'invert(100%)';
            }

            if (graph.isEnabled()) {
                btn.style.cursor = 'pointer';
            }

            mxEvent.addListener(btn, 'click', function (evt) {
                if (graph.isEnabled()) {
                    var value = null;

                    graph.getModel().beginUpdate();
                    try {
                        value = (mxUtils.getValue(style, 'locked', '0') == '1') ? null : '1';
                        graph.setCellStyles('locked', value, [child]);
                    }
                    finally {
                        graph.getModel().endUpdate();
                    }

                    if (value == '1') {
                        graph.removeSelectionCells(graph.getModel().getDescendants(child));
                    }

                    mxEvent.consume(evt);
                }
            });

            left.appendChild(btn);

            var span = document.createElement('span');
            mxUtils.write(span, label);
            span.style.display = 'block';
            span.style.whiteSpace = 'nowrap';
            span.style.overflow = 'hidden';
            span.style.textOverflow = 'ellipsis';
            span.style.position = 'absolute';
            span.style.left = '52px';
            span.style.right = '8px';
            span.style.top = '8px';

            left.appendChild(span);
            ldiv.appendChild(left);

            if (graph.isEnabled()) {
                // Fallback if no drag and drop is available
                if (mxClient.IS_TOUCH || mxClient.IS_POINTER ||
                    (mxClient.IS_IE && document.documentMode < 10)) {
                    var right = document.createElement('div');
                    right.style.display = 'block';
                    right.style.textAlign = 'right';
                    right.style.whiteSpace = 'nowrap';
                    right.style.position = 'absolute';
                    right.style.right = '16px';
                    right.style.top = '6px';

                    // Poor man's change layer order
                    if (index > 0) {
                        var img2 = document.createElement('a');

                        img2.setAttribute('title', mxResources.get('toBack'));

                        img2.className = 'geButton';
                        img2.style.cssFloat = 'none';
                        img2.innerHTML = '&#9660;';
                        img2.style.width = '14px';
                        img2.style.height = '14px';
                        img2.style.fontSize = '14px';
                        img2.style.margin = '0px';
                        img2.style.marginTop = '-1px';
                        right.appendChild(img2);

                        mxEvent.addListener(img2, 'click', function (evt) {
                            if (graph.isEnabled()) {
                                graph.addCell(child, graph.model.root, index - 1);
                            }

                            mxEvent.consume(evt);
                        });
                    }

                    if (index >= 0 && index < layerCount - 1) {
                        var img1 = document.createElement('a');

                        img1.setAttribute('title', mxResources.get('toFront'));

                        img1.className = 'geButton';
                        img1.style.cssFloat = 'none';
                        img1.innerHTML = '&#9650;';
                        img1.style.width = '14px';
                        img1.style.height = '14px';
                        img1.style.fontSize = '14px';
                        img1.style.margin = '0px';
                        img1.style.marginTop = '-1px';
                        right.appendChild(img1);

                        mxEvent.addListener(img1, 'click', function (evt) {
                            if (graph.isEnabled()) {
                                graph.addCell(child, graph.model.root, index + 1);
                            }

                            mxEvent.consume(evt);
                        });
                    }

                    ldiv.appendChild(right);
                }

                if (mxClient.IS_SVG && (!mxClient.IS_IE || document.documentMode >= 10)) {
                    ldiv.setAttribute('draggable', 'true');
                    ldiv.style.cursor = 'move';
                }
            }

            mxEvent.addListener(ldiv, 'dblclick', function (evt) {
                var nodeName = mxEvent.getSource(evt).nodeName;

                if (nodeName != 'INPUT' && nodeName != 'IMG') {
                    renameLayer(child);
                    mxEvent.consume(evt);
                }
            });

            if (graph.getDefaultParent() == child) {
                ldiv.style.background = (!Editor.isDarkMode()) ? '#e6eff8' : '#505759';
                ldiv.style.fontWeight = (graph.isEnabled()) ? 'bold' : '';
                selectionLayer = child;
            }

            mxEvent.addListener(ldiv, 'click', function (evt) {
                if (graph.isEnabled()) {
                    graph.setDefaultParent(defaultParent);
                    graph.view.setCurrentRoot(null);

                    if (mxEvent.isShiftDown(evt)) {
                        graph.setSelectionCells(child.children);
                    }

                    mxEvent.consume(evt);
                }
            });

            listDiv.appendChild(ldiv);
        };

        // Cannot be moved or deleted
        for (var i = layerCount - 1; i >= 0; i--) {
            (mxUtils.bind(this, function (child) {
                addLayer(i, graph.convertValueToString(child) ||
                    mxResources.get('background'), child, child);
            }))(graph.model.getChildAt(graph.model.root, i));
        }

        var label = graph.convertValueToString(selectionLayer) || mxResources.get('background');
        removeLink.setAttribute('title', mxResources.get('removeIt', [label]));
        duplicateLink.setAttribute('title', mxResources.get('duplicateIt', [label]));

        if (graph.isSelectionEmpty()) {
            insertLink.className = 'geButton mxDisabled';
        }

        updateLayerDot();
    };

    refresh();
    graph.model.addListener(mxEvent.CHANGE, refresh);
    graph.addListener('defaultParentChanged', refresh);

    graph.selectionModel.addListener(mxEvent.CHANGE, function () {
        if (graph.isSelectionEmpty()) {
            insertLink.className = 'geButton mxDisabled';
        }
        else {
            insertLink.className = 'geButton';
        }

        updateLayerDot();
    });

    this.window = new mxWindow(mxResources.get('layers'), div, x, y, w, h, true, true);
    this.window.minimumSize = new mxRectangle(0, 0, 150, 120);
    this.window.destroyOnClose = false;
    this.window.setMaximizable(false);
    this.window.setResizable(true);
    this.window.setClosable(true);
    this.window.setVisible(true);

    this.init = function () {
        listDiv.scrollTop = listDiv.scrollHeight - listDiv.clientHeight;
    };

    this.window.addListener(mxEvent.SHOW, mxUtils.bind(this, function () {
        this.window.fit();
    }));

    // Make refresh available via instance
    this.refreshLayers = refresh;

    this.window.setLocation = function (x, y) {
        var iw = window.innerWidth || document.body.clientWidth || document.documentElement.clientWidth;
        var ih = window.innerHeight || document.body.clientHeight || document.documentElement.clientHeight;

        x = Math.max(0, Math.min(x, iw - this.table.clientWidth));
        y = Math.max(0, Math.min(y, ih - this.table.clientHeight - ((urlParams['sketch'] == '1') ? 3 : 48)));

        if (this.getX() != x || this.getY() != y) {
            mxWindow.prototype.setLocation.apply(this, arguments);
        }
    };

    var resizeListener = mxUtils.bind(this, function () {
        var x = this.window.getX();
        var y = this.window.getY();

        this.window.setLocation(x, y);
    });

    mxEvent.addListener(window, 'resize', resizeListener);

    this.destroy = function () {
        mxEvent.removeListener(window, 'resize', resizeListener);
        this.window.destroy();
    }
};
