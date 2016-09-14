;(function ($, document, window, undefined) {
  $(document).ready(function() {
    var lang = $('.timeline').data('lang') || 'en';
    moment.locale(lang);

    $('.timeline .circle').tooltipster({
      functionInit: function(instance, helper) {
        var $tooltip = $(helper.origin).find('.tooltip').detach();
        var $due = $tooltip.find('.due > strong');

        var now = moment.unix(Math.round(Date.now()/1000));
        var due = moment.unix(parseInt($due.text() || 0));

        $due.text(due.from(now));
        instance.content($tooltip);
      },
      delay: 200,
      IEmin: 11,
      theme: 'tooltipster-shadow',
      side: 'bottom'
    });
  });
}(jQuery, document, window, undefined));


