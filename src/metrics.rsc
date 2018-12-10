module metrics

import IO;
import Set;
import Relation;
import Map;
import List;
import String;
import util::Resources;

// returns the number of lines of code in the source code files of the project
public int getProjectLOC(loc project) { 
  int tloc = 0;
  Resource r = getProject(project);
  
  // get a list of all java sorce code files files in the project
  set[loc] files = { a | /file(a) <- r, a.extension == "java" };
    
  // from all files, count the number of lines, excluding blank lines, 
  // comment lines and java annotations (//, /*, */, lines starting with * and @) 
  for(j <- files) {
  	list[str] sl = [a | a <- readFileLines(j), !(isNoise(a))];
  	//for (l <- sl) println(l);
  	tloc += size(sl);
  }
  //println("total LOC: <tloc>");
  return tloc;
}

// returns a list with all (cleaned-up := trimmed + comments etc. removed) lines of code from the project
public list[str] getProjectCodeListing(loc project) { 
  int tloc = 0;
  list[str] sl = [];
  Resource r = getProject(project); 
  set[loc] files = { a | /file(a) <- r, a.extension == "java" }; 
  for(j <- files) {
  	sl += [trim(a) | a <- readFileLines(j), !(isNoise(a))];
  }
  return sl;
} 

// check if a line contains noise (and can be removed)
public bool isNoise(str line) {
	return (/^[\s]*[\/]{2}/ := line || /^[\s]*$/ := line || /^[\s]*[\/\*@]/ := line);
} 

// count the Lines Of Code (LOC) in a string
public int countLOC(loc l, str s) {
  int nl = 1; // the minimum length of a method is 1 LOC
  int bl = 0, cl = 0, ml = 0, al = 0;
  
  // count the number of newline characters
  for (/[\n]+/ := s) {
       nl += 1;
  }
  // number of blank lines
  for (/^[\s]*$/ := s) {
      bl += 1;
  }
  // number of comment lines (only lines with comments, not code and //)
  for (/^[\s]*[\/]{2}/m := s) {
  	   cl += 1;
  }
  // number of multiline comments
  for (/\/\*[^*]*\*+(?:[^\/*][^*]*\*+)*\// := s) {
  	  ml += 1;
  } 
  
  // number of annotaions
  for (/^[\s]*[\/\*@]/ := s) {
  	  al += 1;
  } 
  
  // LOC = newlines - (blank lines + comment lines + multicomment) + annotations
  int lc = nl - (bl + cl + ml + al);
  
  // case where the body of the method is filled a commentline only, count as 1 LOC
  if (lc == 0) {
  	lc = 1;
  }
  
  if (lc < 0) {
  	println("<l>: invalid #lines: <lc>, newline(<nl>), blank(<bl>), comment(<cl>), multi-comment(<ml>)");
  }
  
  //println("<l>: loc(<lc>), newline(<nl>), blank(<bl>), comment(<cl>), multi-comment(<ml>)");
  
  return lc;
}

// split the string into seperate lines, remove comment lines etc. and merge back to lower false positive match count
public str cleanString(str s) {
  	return cs = intercalate("\n", [ a | a <- split("\n", s), !(isNoise(a)) ]);
}

// calculate the cyclomatic complexity of the supplied method
public int countComplexity(str s) {
  int count = 1; 
  // remove comments etc. from the string
  str cs = cleanString(s);
  // count the number of branching statements 	  	
  for (/\b(?:if|for|while|case|catch|&&|\|\|)\b/ := cs) {	  	
	count += 1;	       
  }  
  return count;
}

// count the number of asserts in the string
public int countAssert(str s) {
  int count = 0; 
  // remove comments etc. from the string
  str cs = cleanString(s);
  // count the number of assert statements
  for (/assert/i := s) {
       count += 1;
  }
  return count;
}

// count the number of exact clones in a list of strings, solution taken from: 
// https://stackoverflow.com/questions/33446255/why-does-this-rascal-pattern-matching-code-use-so-much-memory-and-time/33451706#33451706
public int findClone(list[str] listing, list[str] pattern)
{
	int match = 0;
    for ([*head, *pattern, *_] := listing) {
        match += 1;
    }
    return match;
} 

// takes a pattern of blocksize from the code listing and slides it
// in steps of blocksize over the code listing to find duplicate code
public int countDuplication(list[str] listing, int blocksize) {
	int dup_tot = 0;

	for (i <- [0..(size(listing) - blocksize + 1)], i % blocksize == 0) {
		list[str] pattern = [a | a <- listing[i..(i+blocksize)]];
		int match = findClone(listing, pattern);		
		if (match > 1) {
			//println("match: <match> at line i: <i>");
			dup_tot += (match - 1) * blocksize;
		}
		
		if (i % 100 == 0) println("   ..<(i*100)/size(listing)>%");
	}
	return dup_tot;
}

