// the semi-colon before function invocation is a safety net against concatenated
// scripts and/or other plugins which may not be closed properly.
;(function ( $, window, document, undefined ) {

  // Create the defaults once
  var pluginName = 'equalColHeight';
  var defaults = {
    childSelector: '>div'
  };

  // The actual plugin constructor
  function Plugin(element, options) {
    this.$element = $(element);

    this.options = $.extend( {}, defaults, options );

    this._defaults = defaults;
    this._name = pluginName;

    this.init();
  }

  Plugin.prototype = {

    // Initialize plugin
    init: function() {

      console.log('init plugin ' + this._name);

      this.$children = this.options.childSelector === false ? this.$element.children() : this.$element.children().find(this.options.childSelector);
      this.lastKnownItemWidth = this.$children.eq(0).width();

      this.addEventListeners();
      this.setItemsHeight();

    },


    // Get largest item width
    getItemWidth: function ($children) {
      var width = 0;
      for (var i = 0, total = $children.length; i < total; i++) {
        var currentWidth = $children.eq(i).outerWidth();
        width = currentWidth > width ? currentWidth : width;
      }
      return width;
    },


    // Retrieve number of items per row
    getItemsPerRow: function ($children) {

      this.itemsPerRow = Math.round(this.$element.outerWidth() / this.getItemWidth($children));
      return this.itemsPerRow;

    },


    getRowHeight: function (row, $children) {

      var height = 0;

      for (var i = 0; i < this.itemsPerRow; i++) {
        var $this = $children.eq(row * this.itemsPerRow + i);
        var thisHeight = $this.height();

        height = thisHeight > height ? thisHeight : height;
      }

      return height;

    },


    setSingleItemHeight: function ($item, height) {

      $item.css({
        'height': height + 'px',
        'position': 'relative'
      });

      $item.find('.list-initiatives__facts').css({
        'position': 'absolute',
        'left': '20px',
        'right': '20px',
        'bottom': '15px'
      });

    },


    resetItemsHeight: function ($children) {

      $children.css({ 'height': 'auto', 'position': 'relative' });
      $children.find('.list-initiatives__facts').css({ 'position': 'static' });

    },


    // Set height of all items; calculate item height per row and set items accordingly
    setItemsHeight: function () {

      var $children = this.options.childSelector === false ? this.$element.children() : this.$element.children().find(this.options.childSelector);
      var rows = Math.ceil($children.length / this.getItemsPerRow($children));

      this.resetItemsHeight($children);

      for (var i = 0; i < rows; i++) {
        var rowItemHeight = this.getRowHeight(i, $children);
        for (var j = 0; j < this.itemsPerRow; j++) {
          this.setSingleItemHeight($children.eq(i * this.itemsPerRow + j), rowItemHeight);
        }
      }

    },


    handleResize: function () {

      var currentItemWidth = this.$children.width();
      // only execute when a difference occurs in the currentItemWidth
      if (this.lastKnownItemWidth !== currentItemWidth) {
        requestAnimFrame($.proxy(this, 'setItemsHeight'));
      }

    },


    addEventListeners: function () {

      this.$element.on('equalColHeight:setHeight', $.proxy(this, 'setItemsHeight'));
      $(window).on('resize', $.proxy(this, 'handleResize'));

    }

  };

  // A really lightweight plugin wrapper around the constructor,
  // preventing against multiple instantiations
  $.fn[pluginName] = function ( options ) {
    return this.each(function () {
      if (!$.data(this, 'plugin_' + pluginName)) {
        $.data(this, 'plugin_' + pluginName, new Plugin( this, options ));

      }
    });
  };

})( jQuery, window, document );
