module FileController

import String;
import util::Resources;

public set[loc] getJavaFiles(str project) {
	Resource p = getProject(|project://<project>/|);
	return { l | /file(l) <- p, l.extension == "java" };
}