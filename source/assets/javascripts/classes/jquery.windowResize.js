// the semi-colon before function invocation is a safety net against concatenated
// scripts and/or other plugins which may not be closed properly.
;(function ( $, window, document, undefined ) {

  // Create the defaults once
  var pluginName = 'windowResize';
  var defaults = { fireOnInit: true };

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
      console.log(this._name, { element: this.$element });

      this.elemWidth = this.$element.width();
      if (this.options.fireOnInit) {
        this.resizeReady(true);
      }

      this.addEventListeners();
    },

    // Add event listeners
    addEventListeners: function () {
      this.$element.on('resize', $.proxy(this, 'handleResize'));
    },

    // Handle window resize
    handleResize: function () {
      clearTimeout(this.timer);
      this.timer = setTimeout($.proxy(this, 'resizeReady'), 100);
    },

    // Trigger event window:resizeReady
    resizeReady: function (initialRequest) {
      var windowWidth = $(window).width();
      var breakpoint, eventData;

      if (windowWidth >= 1200)    { breakpoint = 'desktop-lg'; }
      else if (windowWidth >= 992)  { breakpoint = 'desktop'; }
      else if (windowWidth >= 768)  { breakpoint = 'tablet'; }
      else              { breakpoint = 'phone'; }

      this.$element.trigger({
        type: 'window:resizeReady',
        breakpoint: breakpoint,
        initialRequest: initialRequest ? initialRequest : false
      });
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