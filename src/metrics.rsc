module metrics

import IO;
import Set;
import Relation;
import Map;
import List;
import String;

// count the Lines Of Code (LOC) in a string
public int countLOC(loc l, str s) {
  int nl = 1; // the minimum length of a method is 1 LOC
  int bl = 0, cl = 0, ml = 0;
  
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
  
  // LOC = newlines - (blank lines + comment lines + multicomment)
  int lc = nl - (bl + cl + ml);
  
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

// calculate the cyclomatic complexity of the supplied method
public int countComplexity(str s) {
  int count = 1; 
  // count the number of branching statements
  for (/\b(?:if|for|while|case|catch)\b/ := s) {
       count += 1;
  }
  return count;
}

// count the number of asserts in the string
public int countAssert(str s) {
  int count = 0; 
  // count the number of assert statements
  for (/assert/i := s) {
       count += 1;
  }
  return count;
}

// returns a list with blank lines and comment lines removed
// only returns a list when the clean list is > 6 LOC 
public list[str] cleanListing(list[str] dirtylist, int dsize) {
	list[str] cleanlist = [];
	for (a <- dirtylist) {
		// remove blank lines, comment lines (//) and multi-line comments from list (/*..*/) 
		if (!/^[\s]*[\/]{2}/m := a && !/^[\s]*$/ := a && !/\/\*[^*]*\*+(?:[^\/*][^*]*\*+)*\// := a) {
			cleanlist += a;
		}
	}
	// only return methods of (size >= dsize) lines of code  
	if (size(cleanlist) < dsize) {
		cleanlist = [];
	}
	return cleanlist;
}

// substring search (match individual lines in the project listing):
// search for pattern in the searchlist, advancing 1 line at a time until the end of the list
public int SearchForPattern(list[str] searchlist, list[str] pattern) {
	int hit = 0;
	int match = 0;
	for (i <- [0..(size(searchlist)-size(pattern)+1)]) {
		for (j <- [0..size(pattern)]) {
			if ( !contains(searchlist[i+j], pattern[j]) ) {
				break;
			}
			hit += 1;
		}
		// if a match is found, skip patternsize and continue
		if (hit == size(pattern)) {
			match += 1;
			i += size(pattern);
		}
		hit = 0;
	}
	return match;
}

// takes a pattern of blocksize from the code listing and 
// slides it in steps of blocksize over the code listing to
// find duplicate code
public int countDuplication(list[str] listing, int blocksize) {
	int dup_tot = 0;
	for (i <- [0..(size(listing) - blocksize + 1)], i % blocksize == 0) {
		list[str] pattern = [a | a <- listing[i..(i+blocksize)]];
		int match = SearchForPattern(listing, pattern);
		if (match > 1) {
			//println("match:<match> at line i:<i>");
			dup_tot += (match - 1) * blocksize;
		}
		if (i % 100 == 0) println("   ..<(i*100)/size(listing)>%");
	}
	return dup_tot;
}
