/*
 * course : Software Evolution (IM0202) Assignment 2: Software Visualization
 * authors: Johan van Nispen (836541627) and Dominique Ruts (852059122)
 * date   : 18/01/2019
 */

module visuals

import List;
import qprofile;
import metrics;
import vis::Figure;
import vis::Render;
import vis::KeySym;

import Relation;
import String;
import Map;
import Set;

import IO;

public void visualize(list[MethodStat] ProjectStat_sorted_loc) {
	println("Start visualization...");
	cscale = colorScale(ProjectStat_sorted_loc.complexity, color("green", 0.5), color("red", 0.8));
	//list[loc] names = ProjectStat_sorted_loc.name;	
	t = treemap([
	     box(area(s.size),fillColor(cscale(s.complexity)),popup("Object: <s.name> \nSize: <s.size> \nComplexity: <s.complexity>")

//onMouseDown(bool (int butnr, map[KeyModifier,bool] modifiers) { 
//                                                 println("<ProjectStat_sorted_loc[i].name> - Size: <s.size> - Complexity: <s.complexity>"); 
//                                                 return true;
//                                             } )
                         )  | s <- ProjectStat_sorted_loc, s.complexity > 2 //, i <- [0..size(ProjectStat_sorted_loc)]
     ] );
	render(t);
	println("End visualization...");
}

FProperty popup(str S){
 return mouseOver(box(text(S), size(50), fillColor("lightyellow"),
 grow(1.2),resizable(false)));
}