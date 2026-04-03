window.PostsEdit = {
  init: function() {
    var editor_id = 'frm_post_text';
    var text_editor = CKEDITOR.instances[editor_id];
    return text_editor.on('change', function() {
      text_editor.updateElement();
      return $(editor_id).closest('form').formValidation('revalidateField', 'frm_post[text]');
    });
  }
};

window.PostsUpdate = window.PostsEdit;
