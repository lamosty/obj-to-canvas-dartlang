import 'dart:html';
import 'dart:math' as Math;
import 'package:vector_math/vector_math.dart';
import 'package:color/color.dart';

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
  double _translation = 0.1 / 100;
  final double _scalingFactor = 10.0 / 100.0; // in percent

  final double ZERO = 0.0;

  double _viewPortX, _viewPortY;

  List<Vector3> vertices;
  List faces;
  Matrix4 T;
  Vector3 camera;
  Vector3 light;

  Color color;

  ObjCanvas() {
    _translation *= _zoomFactor;
    camera = new Vector3(0.0, 0.0, 1.0);
    light = new Vector3(0.0, 0.0, 0.0);
    color = new Color.rgb(0, 0, 0);

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
      line = line.replaceAll(new RegExp(r"\s+$"), "");
      List<String> chars = line.split(" ");

      // vertex
      if (chars[0] == "v") {
        vertex = new Vector3(
          double.parse(chars[1]),
          double.parse(chars[2]),
          double.parse(chars[3])
        );


        vertices.add(vertex);

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

    List<Vector3> verticesToDraw = [];

    vertices.forEach((vertex) {
      verticesToDraw.add(new Vector3.copy(vertex));
    });

    verticesToDraw.forEach((Vector3 vertex) {
      return _calcDefaultVertex(vertex);
    });


    faces.forEach((List face) {
      if (_shouldDrawFace(face)) {
        _drawFace(verticesToDraw, face);
      }
    });
  }

  bool _shouldDrawFace(List face) {
    var normalVector = _normalVector3(
        vertices[face[0] - 1],
        vertices[face[1] - 1],
        vertices[face[2] - 1]
    );

    var dotProduct = normalVector.dot(camera);
    double vectorLengths = normalVector.length * camera.length;

    double angleBetween = dotProduct / vectorLengths;

    return angleBetween < 0;
  }

  Vector3 _normalVector3(Vector3 first, Vector3 second, Vector3 third) {
    Vector3 secondFirst = new Vector3.copy(second).sub(first);
    Vector3 secondThird = new Vector3.copy(second).sub(third);

    return new Vector3(
        (secondFirst.y * secondThird.z) - (secondFirst.z * secondThird.y),
        (secondFirst.z * secondThird.x) - (secondFirst.x * secondThird.z),
        (secondFirst.x * secondThird.y) - (secondFirst.y * secondThird.x)
    );
  }

  void _drawFace(List<Vector3> verticesToDraw, List face) {
    Vector3 normalizedLight = new Vector3.copy(light).normalize();

    var normalVector = _normalVector3(
        verticesToDraw[face[0] - 1],
        verticesToDraw[face[1] - 1],
        verticesToDraw[face[2] - 1]
    );

    Vector3 jnv = new Vector3.copy(normalVector).normalize();

    double koef = _scalarMultiplication(jnv, normalizedLight);

    if (koef < 0.0) {
      koef = 0.0;
    }

    Color newColor = new Color();

    newColor.r = (color.r.toDouble() * koef).round();
    newColor.g = (color.g.toDouble() * koef).round();
    newColor.b = (color.b.toDouble() * koef).round();

    _context.fillStyle = newColor.toHexString();
    _context.beginPath();

    bool lastPoint = false;
    int firstVertexX, firstVertexY, secondVertexX, secondVertexY;

    for (int i = 0; i < face.length; i++) {
      if (i + 1 == face.length) {
        lastPoint = true;
      }

      if (lastPoint) {
        firstVertexX = verticesToDraw[face[i] - 1][0].toInt();
        firstVertexY = verticesToDraw[face[i] - 1][1].toInt();
        secondVertexX = verticesToDraw[face[0] - 1][0].toInt();
        secondVertexY = verticesToDraw[face[0] - 1][1].toInt();
      } else {
        firstVertexX = verticesToDraw[face[i] - 1][0].toInt();
        firstVertexY = verticesToDraw[face[i] - 1][1].toInt();
        secondVertexX = verticesToDraw[face[i + 1] - 1][0].toInt();
        secondVertexY = verticesToDraw[face[i + 1] - 1][1].toInt();
      }

      if (i == 0) {
        _context.moveTo(firstVertexX, firstVertexY);
      }

      _context.lineTo(secondVertexX, secondVertexY);
    }

    _context.closePath();
    _context.fill();
  }

  double _scalarMultiplication(Vector3 first, Vector3 second) {
    return (first.x * second.x) + (first.y * second.y) + (first.z * second.z);
  }

  Vector3 _calcDefaultVertex(Vector3 vertex) {
    T = new Matrix4.translationValues(_viewPortX, _viewPortY, ZERO)
      .scale(_zoomFactor, -_zoomFactor);

    return T.transform3(vertex);
  }

  void restartCanvas() {
    _context.clearRect(0, 0, _canvas.width, _canvas.height);
    T = null;
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

    querySelectorAll("input[type=number]").onChange.listen((MouseEvent event) {
      NumberInputElement input = event.target;
      var inputClass = input.classes.first;

      if (inputClass == 'light') {
        _changeLight(input);
        redraw();
      } else if (inputClass == 'color') {
        _changeColor(input);
        redraw();
      }

    });

  }

  void _changeLight(NumberInputElement input) {
    double lightValue = double.parse(input.value);
    var inputDataValue = input.dataset['value'];

    if (inputDataValue == 'X') {
      light.x = lightValue;
    } else if (inputDataValue == 'Y') {
      light.y = -lightValue;
    } else if (inputDataValue == 'Z') {
      light.z = lightValue;
    }
  }

  void _changeColor(NumberInputElement input) {
    int colorValue = int.parse(input.value);
    var inputDataValue = input.dataset['value'];

    if (inputDataValue == 'R') {
      color.r = colorValue;
    } else if (inputDataValue == 'G') {
      color.g = colorValue;
    } else if (inputDataValue == 'B') {
      color.b = colorValue;
    }
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
      T = new Matrix4.rotationY(_degreeToRadian(-_rotation));

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


