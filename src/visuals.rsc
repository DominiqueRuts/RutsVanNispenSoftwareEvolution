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

import util::Math;
import IO;

public void visualize(list[MethodStat] ProjectStat_sorted_loc) {
	println("Start visualization...");
	cscale = colorScale(ProjectStat_sorted_loc.complexity, color("green", 0.5), color("red", 0.8));
	//list[loc] names = ProjectStat_sorted_loc.name;	
	t = treemap([
	     box(area(s.size),fillColor(cscale(s.complexity)),popup("Object: <clearString(s.name)> \nSize: <s.size> \nComplexity: <s.complexity>")

//onMouseDown(bool (int butnr, map[KeyModifier,bool] modifiers) { 
//                                                 println("<ProjectStat_sorted_loc[i].name> - Size: <s.size> - Complexity: <s.complexity>"); 
//                                                 return true;
//                                             } )
                         )  | s <- ProjectStat_sorted_loc, s.complexity > 2 //, i <- [0..size(ProjectStat_sorted_loc)]
     ] );
	//render(t);
	
	
	
	e1 = circles(ProjectStat_sorted_loc);
	
	render(e1);
	
	println("End visualization...");
}

FProperty popup(str s){
 return mouseOver(box(text(s), size(50), fillColor("lightyellow"),
 grow(1.2),resizable(false)));
}

Figure circles(list[MethodStat] ProjectStat_sorted_loc){
	MethodStat mFirst = head(ProjectStat_sorted_loc);
	MethodStat mLast = last(ProjectStat_sorted_loc);
	
 return box(overlay([ellipse(width(s.complexity), height(s.complexity), align(s.size/mFirst.size,1-toReal(s.complexity)/252), fillColor(color("blue", 0.6)),resizable(false),popup("Object: <getFileName(s.name)> \nSize: <s.size> \nComplexity: <s.complexity>")) | s <- ProjectStat_sorted_loc]),size(mFirst.size,500)) ;
}

private str getFileName(loc s) {
	str inputString = s.path;
	int lastSlash = findLast(inputString, "/");
	str sToDisplay = substring(inputString, 0, lastSlash);
	sToDisplay = substring(sToDisplay, findLast(sToDisplay, "/")+1);
	
	return sToDisplay;
}

private str clearString(loc s) {
	str inputString = s.path;
	int lastSlash = findLast(inputString, "/");
	str sToDisplay = substring(inputString, lastSlash+1);
	sToDisplay = substring(sToDisplay, 0, findFirst(sToDisplay, "("));
	
	return sToDisplay;
}