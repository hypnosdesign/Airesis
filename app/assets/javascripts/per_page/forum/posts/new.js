window.PostsNew = {
  init: function() {
    var text_editor = CKEDITOR.instances['frm_post_text'];
    return text_editor.on('change', function() {
      text_editor.updateElement();
      console.log('init');
      return $('form').formValidation('revalidateField', 'frm_post[text]');
    });
  }
};

window.PostsCreate = window.PostsNew;
