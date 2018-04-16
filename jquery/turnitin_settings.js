jQuery(document).ready(function($) {
    $('input[name="errors_select_all"]').click(function() {
        if ($(this).prop('checked')) {
            $('.errors_checkbox').prop('checked', true);
        } else {
            $('.errors_checkbox').prop('checked', false);
        }
    });

    $(".pp-resubmit-files").click(function() {
        var submission_ids = [];
        $('.errors_checkbox:checked').each(function(i){
            submission_ids[i] = $(this).val();
        });

        $.ajax({
            type: "POST",
            url: "ajax.php",
            dataType: "json",
            data: {action: "resubmit_events", submission_ids: submission_ids, sesskey: M.cfg.sesskey},
            success: function(data) {
                window.location.href = window.location.href + "&resubmitted=success";
            },
            error: function(data, response) {
                window.location.href = window.location.href + "&resubmitted=errors";
            }
        });
    })

    // Disable/enable resubmit selected files when one or more are selected.
    $(document).on('click', '.errors_checkbox, input[name="errors_select_all"]', function() {
        if ($('.errors_checkbox:checked').length > 0) {
            $('.pp-resubmit-files').removeAttr('disabled');
        } else {
            $('.pp-resubmit-files').attr('disabled', 'disabled');
        }
    });

    $("input[name=connection_test]").click(function() {
        if ($('#id_plagiarism_accountid').val() != '' || $('#id_plagiarism_secretkey').val() != '') {
            $('.test_connection').show();
            $('#test_link').show();
        }

        $('#id_plagiarism_accountid, #id_plagiarism_secretkey, #id_plagiarism_apiurl').keyup(function() {
            $('#testing_container').hide();

            var accountid = $('#id_plagiarism_accountid').val();
            var accountshared = $('#id_plagiarism_secretkey').val();

            // Make sure they aren't empty strings.
            accountid = accountid.trim();
            accountshared = accountshared.trim();
            if (accountid.length == 0 || accountshared.length == 0) {
                $('#test_result').hide();
                $('.test_connection').hide();
            } else {
                $('.test_connection').show();
                $('#test_link').show();
            }
        });

        // Change Url depending on Settings page.
        var url = "ajax.php";
        if ($('.settingsform fieldset div.formsettingheading').length > 0) {
            url = "../plagiarism/turnitin/ajax.php";
        }

        var accountid = $('#id_plagiarism_accountid').val();
        var accountshared = $('#id_plagiarism_secretkey').val();
        var accounturl = $('#id_plagiarism_apiurl').val();

        $.ajax({
            type: "POST",
            url: url,
            dataType: "json",
            data: {
                action: "test_connection",
                sesskey: M.cfg.sesskey,
                accountid: accountid,
                accountshared: accountshared,
                url: accounturl},
            success: function(data) {
                eval(data);

                // Store connection test selector.
                var ct = $("input[name=connection_test]");

                if (data.connection_status === 200) {
                    ct.removeClass("connection-test-failed");
                    ct.addClass("connection-test-success");
                    ct.attr('value', M.str.plagiarism_turnitin.connecttestsuccess);
                } else {
                    ct.removeClass("connection-test-success");
                    ct.addClass("connection-test-failed");
                    ct.attr('value', M.str.plagiarism_turnitin.connecttestfailed);
                }
                $('#testing_container').hide();
            }
        });
    });
});