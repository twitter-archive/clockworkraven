$(function() {
  var scrollEl = $('html,body');

  if($.browser.safari) {
    scrollEl = $("body");
  }

  $(window).scroll(function() {
    if(scrollEl.scrollTop()  == 0) {
      $('body').addClass('scroll-top');
    }
    else {
      $('body').removeClass('scroll-top');
    }
  });

  $(window).scroll();
})