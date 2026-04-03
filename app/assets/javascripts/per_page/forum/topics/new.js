window.TopicsNew = {
  init: function() {
    var form = $('#new_frm_topic');
    var text_editor = CKEDITOR.instances['frm_topic_posts_attributes_0_text'];
    return text_editor.on('change', function() {
      text_editor.updateElement();
      return form.formValidation('revalidateField', 'frm_topic[posts_attributes][0][text]');
    });
  }
};

window.TopicsCreate = window.TopicsNew;
