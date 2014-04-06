import 'dart:html';
import 'dart:math' as Math;
import 'package:vector_math/vector_math.dart';

void main() {
  ObjCanvas objCanvas = new ObjCanvas();
}

class ObjCanvas {
  FormElement _readForm;
  InputElement _fileInput;
  CanvasElement _canvas;
  CanvasRenderingContext2D _context;

  final double _zoomFactor = 100.0;

  final double _rotation = 5.0; // in degrees
  double _translation = 0.1;
  final double _scalingFactor = 10.0 / 100.0; // in percent

  final double ZERO = 0.0;

  double _viewPortX, _viewPortY;

  List<Vector3> vertices;
  List faces;
  Matrix4 T;

  ObjCanvas() {
    _translation *= _zoomFactor;

    _initializeCanvas();
    _initializeFileUpload();
    _initializeInterfaceControllers();
  }

  _initializeFileUpload() {
    _readForm = querySelector("#read");
    _fileInput = querySelector("#files");

    _fileInput.onChange.listen((e) => _onFileInputChange());
  }

  _initializeCanvas() {
    _canvas = querySelector("#canvas");
    _context = _canvas.getContext("2d");

    _viewPortX = (_canvas.width / 2).toDouble();
    _viewPortY = (_canvas.height / 2).toDouble();
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
        vertices = parsedFile["vertices"];
        faces = parsedFile["faces"];

        _drawFaces();

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

    Vector3 vertex;

    lines.forEach((String line) {
      List<String> chars = line.split(" ");

      // vertex
      if (chars[0] == "v") {
        vertex = new Vector3(
          double.parse(chars[1]),
          double.parse(chars[2]),
          double.parse(chars[3])
        );

        vertices.add(_calcDefaultVertex(vertex));

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

  void _drawFaces() {
    _context.beginPath();

    int firstVertexX, firstVertexY, secondVertexX, secondVertexY;

    faces.forEach((List face) {
      for (int i = 0; i < face.length; i++) {
        if (i + 1 == face.length) {
          firstVertexX = vertices[face[i] - 1][0].toInt();
          firstVertexY = vertices[face[i] - 1][1].toInt();
          secondVertexX = vertices[face[0] - 1][0].toInt();
          secondVertexY = vertices[face[0] - 1][1].toInt();
        } else {
          firstVertexX = vertices[face[i] - 1][0].toInt();
          firstVertexY = vertices[face[i] - 1][1].toInt();
          secondVertexX = vertices[face[i + 1] - 1][0].toInt();
          secondVertexY = vertices[face[i + 1] - 1][1].toInt();
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

  Vector3 _calcDefaultVertex(Vector3 vertex) {
    T = new Matrix4.translationValues(_viewPortX, _viewPortY, ZERO)
      .scale(_zoomFactor, -_zoomFactor);

    return T.transform3(vertex);
  }

  void restartCanvas() {
    _context.clearRect(0, 0, _canvas.width, _canvas.height);
  }

  void _initializeInterfaceControllers() {
    querySelectorAll("button").onClick.listen((MouseEvent event) {
      ButtonElement btn = event.target;
      var btnClass = btn.classes.first;
      var btnDataValue = btn.dataset['value'];

      if (btnClass == 'rotate') {
        rotateModel(btnDataValue);
        redraw();
      } else if (btnClass == 'translate') {
        translateModel(btnDataValue);
        redraw();
      } else if (btnClass == 'scale') {
        scaleModel(btnDataValue);
        redraw();
      }
    });

  }

  double _degreeToRadian(double degree) {
    return degree * (Math.PI / 180.0);
  }

  void rotateModel(String axis) {
    if (axis == "X") {
      T = new Matrix4.rotationX(_degreeToRadian(_rotation));

      vertices.forEach((vector) {
        return T.transform3(vector);
      });
    } else if (axis == "Y") {
      T = new Matrix4.rotationY(_degreeToRadian(_rotation));

      vertices.forEach((vector) {
        return T.transform3(vector);
      });

    } else if (axis == "Z") {
      T = new Matrix4.rotationZ(_degreeToRadian(_rotation));

      vertices.forEach((vector) {
        return T.transform3(vector);
      });

    }
  }

  void translateModel(String axis) {
    if (axis == "X") {
      T = new Matrix4.translationValues(_translation, ZERO, ZERO);

      vertices.forEach((vector) {
        return T.transform3(vector);
      });
    } else if (axis == "Y") {
      T = new Matrix4.translationValues(ZERO, _translation, ZERO);

      vertices.forEach((vector) {
        return T.transform3(vector);
      });
    } else if (axis == "Z") {
      T = new Matrix4.translationValues(ZERO, ZERO, _translation);

      vertices.forEach((vector) {
        return T.transform3(vector);
      });
    }
  }

  void scaleModel(String moreOrLessSign) {
    if (moreOrLessSign == "+") {
      double scale = 1.0 + _scalingFactor;
      T = new Matrix4.diagonal3Values(scale, scale, scale);

      vertices.forEach((vector) {
        return T.transform3(vector);
      });
    } else if (moreOrLessSign == "-") {
      double scale = 1.0 - _scalingFactor;
      T = new Matrix4.diagonal3Values(scale, scale, scale);

      vertices.forEach((vector) {
        return T.transform3(vector);
      });
    }
  }

  void redraw() {
    restartCanvas();
    _drawFaces();
  }
}


