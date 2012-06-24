//   Copyright (c) 2012, John Evans
//
//   http://www.lucastudios.com/contact
//   John: https://plus.google.com/u/0/115427174005651655317/about
//
//   Licensed under the Apache License, Version 2.0 (the "License");
//   you may not use this file except in compliance with the License.
//   You may obtain a copy of the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//   Unless required by applicable law or agreed to in writing, software
//   distributed under the License is distributed on an "AS IS" BASIS,
//   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//   See the License for the specific language governing permissions and
//   limitations under the License.


/**
* Helper class for working with Buckshot templates
*/
class Template {
  
  final List<IPresentationFormatProvider> providers;
  
  Template()
  :
    providers = [new XmlTemplateProvider(),
                 new JSONTemplateProvider(),
                 new YAMLTemplateProvider()];

  /// Performs a search of the element tree starting from the given
  /// [FrameworkElement] and returns the first named Element matching
  /// the given name.
  ///
  /// ## Instead use:
  ///     Buckshot.namedElements[elementName];
  static FrameworkElement findByName(String name, FrameworkElement startingWith){

    if (startingWith.name != null && startingWith.name == name) return startingWith;

    if (!startingWith.isContainer) return null;

    var cc = startingWith._stateBag[FrameworkObject.CONTAINER_CONTEXT];
    if (cc is List){
      for (final el in cc){
        var result = findByName(name, el);
        if (result != null) return result;
      }
    }else if (cc is FrameworkProperty){
      FrameworkElement obj = getValue(cc);
      if (obj == null || !(obj is FrameworkElement)) return null;
      return findByName(name, obj);
    }else{
      return null;
    }
  }
  
  /**
  * # Usage #
  *     //Retrieves the template from the current web page
  *     //and returns a String containing the template 
  *     //synchronously.
  *     getTemplate('#templateID').then(...);
  *
  *     //Retrieves the template from the URI (same domain)
  *     //and returns a String containing the template
  *     //asynchronously in a Future<String>.
  *     getTemplate('/relative/path/to/templateName.xml').then(...);
  *
  * Use the [deserialize] method to convert a template into an object structure.
  */
  static getTemplate(String from){   
    if (from.startsWith('#')){
      var result = document.query(from);
      return result == null ? null : result.text.trim();
      
    }else{
      //TODO cache...
      
      var c = new Completer();
      var r = new XMLHttpRequest();
      r.on.readyStateChange.add((e){
        if (r.readyState != 4){ 
          c.complete(null);          
        }else{
          c.complete(r.responseText.trim());
        }
      });
      
      try{              
        r.open('GET', from, true);
        r.setRequestHeader('Accept', 'text/xml');
        r.send();
      }catch(Exception e){
        c.complete(null);
      }
      
      return c.future;
    }
  }
  
  /**
  * Takes a buckshot Template and attempts deserialize it into an object
  * structure.
  */
  static FrameworkElement deserialize(String buckshotTemplate){
    final t = new Template();
    
    for(final p in t.providers){
      if(p.isFormat(buckshotTemplate)){
        return p.deserialize(buckshotTemplate);
      }
    }
  }
}