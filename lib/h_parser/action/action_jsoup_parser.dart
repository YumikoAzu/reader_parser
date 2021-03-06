import 'package:html/dom.dart';

import '../regexp_rule.dart';
import 'action_parser.dart';

class ActionJsoupParser extends ActionParser {
  final INVALID = 99999999;

  ActionJsoupParser(Element element, String htmlString)
      : super(element, htmlString);

  @override
  List<Element> getElementsEachRule(String rule, bool needFilterText) {
    //.book-info-bookstate@span@text
    //.lastchapter@span!0:1@text
    //class.odd.0
    //class.grid@tbody@td@children
    List<String> u_split = rule.split(RegexpRule.DELIMITER);

    var filterReg = "";
    // 获取文本内容的类型
    if (u_split.length >= 1 && needFilterText) {
      filterReg = u_split.removeLast();
    }

    var elements = List<Element>();
    elements.add(mElement);

    //不执行，只过滤子element然后获得字符串规则
    if (u_split.isEmpty && needFilterText) {
      //pass
    } else if (u_split.isEmpty) {
      throw Exception('不支持的规则->$rule');
    }

    //逐条执行
    for (var ruleEach in u_split) {
      var each = ruleEach.split(RegexpRule.JSOUP_SPLIT);

      //类型
      var temp = each[0].split(RegexpRule.JSOUP_EXCLUDE_CHAR);
      var actionType = temp[0];
      var excludeIndex = List<int>();
      //需要排除指定序号的元素
      if (temp.length == 2) {
        var x = temp[1].split(RegexpRule.JSOUP_EXCLUDE_INT);
        for (var i in x) {
          excludeIndex.add(int.parse(i));
        }
      }
      //属性值
      var temp2 = [];
      if(each.length > 1){
        temp2 = each[1].split(RegexpRule.JSOUP_EXCLUDE_CHAR);
      }
      var property = temp2.isNotEmpty?temp2[0]:'';
      var excludeIndexP = List<int>();
      //需要排除指定序号的元素
      if (temp2.length == 2) {
        var x = temp2[1].split(RegexpRule.JSOUP_EXCLUDE_INT);
        for (var i in x) {
          excludeIndexP.add(int.parse(i));
        }
      }
      //序号
      var cIndex = INVALID;
      if(each.length == 3){
        cIndex = int.parse(each[2]);
      }

      var tempElements = List<Element>();

      //操作类型
      if (actionType == RegexpRule.JSOUP_SUPPORT_CHILD) {
        for(var element in elements){
          tempElements.addAll(excludeElements(element.children, excludeIndex));
        }

      } else if (actionType == RegexpRule.JSOUP_SUPPORT_CLASS) {
        for(var element in elements){
          var ctemp = element.getElementsByClassName(property);
          ctemp = excludeElements(ctemp, excludeIndexP);
          tempElements.addAll(addIndexElement(ctemp, cIndex));
        }
      } else if (actionType == RegexpRule.JSOUP_SUPPORT_TAG) {
        for(var element in elements){
          var ctemp = element.getElementsByTagName(property);
          ctemp = excludeElements(ctemp, excludeIndexP);
          tempElements.addAll(addIndexElement(ctemp, cIndex));
        }
      } else if (actionType == RegexpRule.JSOUP_SUPPORT_TEXT) {
        for(var element in elements) {
          tempElements.addAll(_findText(property, element));
        }
      } else if (actionType == RegexpRule.JSOUP_SUPPORT_ID) {
        for(var element in elements) {
          var ctemp = element.querySelector("#$property");
          tempElements.add(ctemp);
        }
      }
      else {
        for(var element in elements) {
          var ctemp = element.querySelectorAll(actionType);
          if (ctemp != null) {
            ctemp = excludeElements(ctemp, excludeIndex);
            tempElements.addAll(ctemp);
          }
        }
      }
      elements = tempElements;

    }//for
    if(needFilterText){
      for(var element in elements){
        filterText(element, filterReg, replaceRegexp);
      }
    }

    return elements;
  }


  List<Element> _findText(String text,Element element){
    var tempElements = List<Element>();
    for(var c in element.children){
      var nodes = c.nodes;
      for (var value in nodes) {
        if(value.nodeType == Node.TEXT_NODE){
          var t = value.text;
          if(t.contains(text)){
            tempElements.add(c);
          }
        }
      }
      tempElements.addAll(_findText(text, c));
    }
    return tempElements;
  }

  List<Element> excludeElements(List<Element> elements,List<int> eList){
    if(eList.isEmpty){
      return elements;
    }
    var copy = List<Element>();
    for(var i = 0;i<elements.length;i++){
      var needBreak = false;
      for(var j in eList){
        var k = negativeGetIndex(elements.length, j);
        if(i == k){
          needBreak = true;
        }
      }
      if(!needBreak){
        copy.add(elements[i]);
      }
    }
    return copy;

  }

  List<Element> addIndexElement(List<Element> find_result,int keep){
    var temp = List<Element>();
    if(find_result == null){
      return temp;
    }
    if(keep != INVALID){
      temp.add(find_result[negativeGetIndex(find_result.length, keep)]);
    }else{
      temp.addAll(find_result);
    }
    return temp;
  }

  @override
  List<String> getStrings(String rule) {
    var temp = List<String>();
    var elementList = getElements(rule,true);
    for(var e in elementList){
      temp.add(e.text);
    }
    return temp;
  }

  @override
  String formatRule(String rule) {
    if(rule.startsWith(RegExp('[+-]'))){
      return rule.substring(1);
    }
    return rule;
  }
}
