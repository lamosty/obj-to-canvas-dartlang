import 'dart:html';
import 'dart:math' as Math;

void main() {
  ObjCanvas objCanvas = new ObjCanvas();
}

class ObjCanvas {
  FormElement _readForm;
  InputElement _fileInput;
  CanvasElement _canvas;
  CanvasRenderingContext2D _context;

  int _zoomFactor = 200;

  int _viewPortX, _viewPortY;

  ObjCanvas() {
    _initializeCanvas();
    _initializeFileUpload();
  }

  _initializeFileUpload() {
    _readForm = querySelector("#read");
    _fileInput = querySelector("#files");
    
    _fileInput.onChange.listen((e) => _onFileInputChange());

  }
  
  _initializeCanvas() {
    _canvas = querySelector("#canvas");
    _context = _canvas.getContext("2d");

    _viewPortX = (_canvas.width / 2).toInt();
    _viewPortY = (_canvas.height / 2).toInt();
  }
  
  _onFileInputChange() {
    restartCanvas();
    _onFilesSelected(_fileInput.files);
  }
  
  _onFilesSelected(List<File> files) {
    for (File file in files) {
      var reader = new FileReader();
      
      reader.onLoad.listen((e) {
        Map parsedFile = _parseObjString(reader.result);
        _drawFaces(parsedFile["vertices"], parsedFile["faces"]);

      });
      
      reader.readAsText(file);
    }
  }

  /**
   * Returns {'vertices': 2D list of vertices,
   *          'faces': 2D list of faces}
   */
  Map<String, List<List<int>>>_parseObjString(String objString) {
    List vertices = [];
    List faces = [];
    List<int> face = [];

    List lines = objString.split("\n");

    double coordX, coordY;

    lines.forEach((String line) {
      List<String> chars = line.split(" ");

      // vertex
      if (chars[0] == "v") {
        coordX = double.parse(chars[1]);
        coordY = double.parse(chars[2]);

        if (!((coordX >= -3 && coordX <= 3) &&
        (coordY >= -2 && coordY <= 2))) {
          return;
        }

        vertices.add(_calcVertex(coordX, coordY));

        // face
      } else if (chars[0] == "f") {
        for (var i = 1; i < chars.length; i++) {
          face.add(int.parse(chars[i]));
        }

        faces.add(face);
        face = [];
      }
    });

    return {
      'vertices' : vertices,
      'faces' : faces
    };
  }

  void _drawFaces(List vertices, List faces) {
    _context.beginPath();

    int firstVertexX, firstVertexY, secondVertexX, secondVertexY;

    faces.forEach((List face) {
      for (int i = 0; i < face.length; i++) {
        if (i + 1 == face.length) {
          firstVertexX = vertices[face[i] - 1][0];
          firstVertexY = vertices[face[i] - 1][1];
          secondVertexX = vertices[face[0] - 1][0];
          secondVertexY = vertices[face[0] - 1][1];
        } else {
          firstVertexX = vertices[face[i] - 1][0];
          firstVertexY = vertices[face[i] - 1][1];
          secondVertexX = vertices[face[i + 1] - 1][0];
          secondVertexY = vertices[face[i + 1] - 1][1];
        }
        _drawLine(firstVertexX, firstVertexY, secondVertexX, secondVertexY);
      }
    });
    _context.closePath();
  }

  void _drawLine(int firstVertexX, int firstVertexY,
            int secondVertexX, int secondVertexY) {
    _context.moveTo(firstVertexX, firstVertexY);
    _context.lineTo(secondVertexX, secondVertexY);
    _context.stroke();
  }

  List<int> _calcVertex(double vertexX, double vertexY) {
    vertexX = (vertexX * _zoomFactor) + _viewPortX;
    vertexY = (vertexY * _zoomFactor) + _viewPortY;

    return [vertexX.toInt(), vertexY.toInt()];
  }

  void restartCanvas() {
    _context.clearRect(0, 0, _canvas.width, _canvas.height);
  }
}


