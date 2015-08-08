(function() {
  function resolveTranslationValue(value, dimension) {
    var v = /^(-?\d+)px$/.exec(value);
    if (v) {
        return parseInt(v[1]);
    }

    v = /^(-?\d+)%$/.exec(value);
    if (v) {
        return dimension * parseInt(v[1]) / 100;
    }

    return 0;
  }

  function resolveCssTranslate(element) {
    var x = 0, y = 0;

    var transform = element.style.transform ||
            element.style.webkitTransform ||
            element.style.mozTransform ||
            element.style.msTransform ||
            element.style.oTransform;

    if (!!transform) {
        var regex = /translate\(\s*(\-?[\d\w%]+)\s*,\s*(\-?[\d\w%]+)\s*\)/g;

        var translations = transform.match(regex);

        if (translations) {
            for (var i = 0; i < translations.length; ++i) {
                var groups = regex.exec(translations[i]);
                var translationX = groups[1],
                    translationY = groups[2];
                x += resolveTranslationValue(translationX, element.offsetWidth);
                y += resolveTranslationValue(translationY, element.offsetHeight);
            }
        }
    }

    return {
        xOffset: x,
        yOffset: y
    };
  }

  function getFrameInScreen(element) {
    var xPosition = 0;
    var yPosition = 0;
    var width = element.offsetWidth;
    var height = element.offsetHeight;

    while (element) {
        var transform = resolveCssTranslate(element);

        xPosition += element.offsetLeft -
            element.scrollLeft +
            transform.xOffset +
            element.clientLeft;

        yPosition += element.offsetTop -
            element.scrollTop +
            transform.yOffset +
            element.clientTop;

        element = element.offsetParent;
    }

    return {x: xPosition, y: yPosition, width: width, height: height};
  }

  function getScreenSize() {
    return {
        width: window.innerWidth,
        height: window.innerHeight
    };
  }

  function clip(position, max) {
      if (position < 0) {
          return 0;
      } else if (position > max) {
          return max;
      } else {
          return position;
      }
  }

  /**
   * @param {HTMLElement} element
   * @param {{left: Number, right: Number, top: Number, bottom: Number}} insets
   *        portion of the screen to exclude from area considered visible
   * @returns {Number} [0..1] - portion of the element currently visible on screen
   */
  window.com.sivintech.elmentVisibleRatio = function(element, insets) {
      var frame = getFrameInScreen(element);
      var screenSize = getScreenSize();

      var position = {
          left: frame.x,
          right: frame.x + frame.width,
          top: frame.y,
          bottom: frame.y + frame.height
      };

      position.left -= insets.left;
      position.right -=  insets.left;
      position.top -= insets.top;
      position.bottom -= insets.top;
      screenSize.width = screenSize.width - insets.left - insets.right;
      screenSize.height = screenSize.height - insets.top - insets.bottom;

      var visibleWidth = clip(position.right, screenSize.width) -
              clip(position.left, screenSize.width),
          visibleHeight = clip(position.bottom, screenSize.height) -
              clip(position.top, screenSize.height),
          visibleRatioH = visibleWidth / frame.width,
          visibleRatioV = visibleHeight / frame.height;

      return visibleRatioH * visibleRatioV;
  };
})();
