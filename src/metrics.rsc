module metrics

import IO;
import Set;
import Relation;
import Map;
import List;
import String;

// count the Lines Of Code (LOC) in a string
public int countLOC(str s) {
  int count = 0;
  // count the number of newline characters
  for (/[\n]+/ := s) {
       count += 1;
  }
  // substract the number of blank lines
  for (/^[\s\t]*$/m := s) {
      if (count > 0) count -= 1;
  }
  // substract the number of comment lines (where comments start at the beginning)
  for (/^[\/\/]+/ := s) {
       if (count > 0) count -= 1;
  }
  // substract the number of multiline comments
  for (/\/\*[^*]*\*+(?:[^\/*][^*]*\*+)*\// := s) {
      if (count > 0) count -= 1;
  } 
  return count;
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
		if (!/^[\/\/]+/ := a && !/^[\s\t]*$/m := a && !/\/\*[^*]*\*+(?:[^\/*][^*]*\*+)*\// := a) {
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
