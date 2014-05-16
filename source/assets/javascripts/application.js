$(document).ready(function(){

  var $document       = $(document);
  var $window       = $(window);
  var $equalColHeight   = $('.equal-heights');

  // Smooth scroll
  $(".js_scrollto").on('click', function(e) {
    e.preventDefault();
    var position = $($(this).attr('href')).offset().top;
    $('html, body').animate({scrollTop: position-20}, 400, 'swing');
  });

  // Start listening for window resize event(s)
  $(window).windowResize(); 

  // Full height according to window - combine with windowResize
  $(window).on('resize',resizeThrottler);
  var resizeTimeout;
  function resizeThrottler() {
      window.clearTimeout(resizeTimeout);
      // ignore resize events as long as an actualResizeHandler execution is in the queue
      resizeTimeout = setTimeout(function() {
          actualResizeHandler();
          // The actualResizeHandler will execute at a rate of 3,5fps
      }, 244);
  }
  function actualResizeHandler() {
    // handle the resize event
    $(window).trigger({
        type: "Mangrove:resized",
        wHeight: $(window).height(),
        wWidth: $(window).width()
    });
  }
  $(window).on('Mangrove:resized',function(e) {
      $(".fullbg").height(e.wHeight); //.width(e.wWidth);
  });
  $(window).trigger('resize');

});
