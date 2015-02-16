<!DOCTYPE html>
<html>
	<head>
    	<meta charset="utf-8">
    	<title>Stormrider</title>
    	<link rel="stylesheet" href="assets/css/main.css">
    	<script src="http://code.jquery.com/jquery-latest.min.js"></script>
    	<link href='http://fonts.googleapis.com/css?family=Prociono' rel='stylesheet' type='text/css'>
    	<script type="text/javascript">
    		$(document).ready(function(){
    			vLang=$( "#language option:selected").val();
    			$.getJSON("language.json",vLang)
					.done(function( json ) {
						switch(vLang) {
							case "english":
								$(".jumbotron .container h1").text(json.language.english.index_title);
								$(".jumbotron .container p").text(json.language.english.index_subtitle);
								$(".container .login-form div .text").attr("placeholder", json.language.english.index_placeholder_text);
								$(".container .login-form div .password").attr("placeholder", json.language.english.index_placeholder_password);
								$(".container .login-form button").text(json.language.english.index_login_button);
								break;
							case "spanish":
								$(".jumbotron .container h1").text(json.language.spanish.index_title);
								$(".jumbotron .container p").text(json.language.spanish.index_subtitle);
								$(".container .login-form div .text").attr("placeholder", json.language.spanish.index_placeholder_text);
								$(".container .login-form div .password").attr("placeholder", json.language.spanish.index_placeholder_password);
								$(".container .login-form button").text(json.language.spanish.index_login_button);
								break;
						}
					})
					.fail(function( jqxhr, textStatus, error ) {
						var err = textStatus + ", " + error;
						console.log( "Request Failed: " + err );
					});
				$( "#language" ).change(function() {
					vLang=$( "#language option:selected").val();
	    			$.getJSON("language.json",vLang)
						.done(function( json ) {
							switch(vLang) {
								case "english":
									$(".jumbotron .container h1").text(json.language.english.index_title);
									$(".jumbotron .container p").text(json.language.english.index_subtitle);
									$(".container .login-form div .text").attr("placeholder", json.language.english.index_placeholder_text);
									$(".container .login-form div .password").attr("placeholder", json.language.english.index_placeholder_password);
									$(".container .login-form button").text(json.language.english.index_login_button);
									break;
								case "spanish":
									$(".jumbotron .container h1").text(json.language.spanish.index_title);
									$(".jumbotron .container p").text(json.language.spanish.index_subtitle);
									$(".container .login-form div .text").attr("placeholder", json.language.spanish.index_placeholder_text);
									$(".container .login-form div .password").attr("placeholder", json.language.spanish.index_placeholder_password);
									$(".container .login-form button").text(json.language.spanish.index_login_button);
									break;
							}
						})
						.fail(function( jqxhr, textStatus, error ) {
							var err = textStatus + ", " + error;
							console.log( "Request Failed: " + err );
						});
				});
			})
    	</script>
	</head>
	<body>
		<select id="language">
			<option value="english" selected="selected">English</option>
			<option value="spanish">Español</option>
		</select> 
		<div class="jumbotron">
	    	<div class="container">
	        	<h1></h1>
	        	<p></p>
			</div>
		</div>
		<div class="container">
			<form class="login-form" action="login.php">
		        <div>
		        	<input type="text" class="text">
		        </div>
		        <div>
		        	<input type="password" class="password">
		        </div>
		        <button type="submit"></button>
		      </form>
	    </div>  
    </body>
</html>