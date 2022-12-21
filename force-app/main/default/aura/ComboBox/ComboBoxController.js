({	
    doAction : function (component, event, helper) {
        var params = event.getParam('arguments');
        if(params!='' && params!=null){
            component.set("v.inputValue", params);
            component.set("v.selectedOption", params);
        }     
    },
    searchHandler : function (component, event, helper) {
        const searchString = event.target.value;
        component.set("v.openDropDown", true);       
    },
    searchString : function (component, event, helper) {
        var searchString = 'https://apps.'+event.target.value+'.babelforce.com/babelconnect/#/app';
        component.set("v.inputValue", searchString);
        component.set("v.selectedOption", searchString);
    },
    
    optionClickHandler : function (component, event, helper) {
        const selectedId = event.target.closest('li').dataset.id;
        const selectedValue = event.target.closest('li').dataset.value;
        component.set("v.inputValue", selectedValue);
        component.set("v.openDropDown", false);
        component.set("v.selectedOption", selectedId);
        
        
    },
    
    clearOption : function (component, event, helper) {
      
        component.set("v.openDropDown", false);
        component.set("v.inputValue", "");
        component.set("v.selectedOption", "");
    },
    
    addEventListener: function(component,event,helpler){
        window.addEventListener('click', function(e){ 
            var t = e.target;
            console.log(t);
            if(t!=null && t.id!=null && t.id!='combobox-id-21'){
                component.set("v.openDropDown", false);
            }
      });
    }

})