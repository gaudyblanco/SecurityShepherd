<%@ page contentType="text/html; charset=iso-8859-1" language="java" import="dbProcs.Getter, utils.*,org.owasp.encoder.Encode" errorPage="" %>

<%
	ShepherdLogManager.logEvent(request.getRemoteAddr(), request.getHeader("X-Forwarded-For"), "DEBUG: scoreboard.jsp *************************");

 if (request.getSession() != null)
 {
 	HttpSession ses = request.getSession();
 	//Getting CSRF Token from client
 	Cookie tokenCookie = null;
 	try
 	{
 		tokenCookie = Validate.getToken(request.getCookies());
 	}
 	catch(Exception htmlE)
 	{
 		ShepherdLogManager.logEvent(request.getRemoteAddr(), request.getHeader("X-Forwarded-For"), "DEBUG(scoreboard.jsp): tokenCookie Error:" + htmlE.toString());
 	}
 	// validateSession ensures a valid session, and valid role credentials
 	// Also, if tokenCookie != null, then the page is good to continue loading
 	if (Validate.validateSession(ses) && tokenCookie != null)
 	{
 		//Log User Name
 		ShepherdLogManager.logEvent(request.getRemoteAddr(), request.getHeader("X-Forwarded-For"), "Scoreboard accessed by: " + ses.getAttribute("userName").toString(), ses.getAttribute("userName"));
 		// Getting Session Variables
 		boolean canSeeScoreboard = ScoreboardStatus.canSeeScoreboard((String)ses.getAttribute("userRole"));
 		//The org.owasp.encoder.Encode class should be used to encode any softcoded data. This should be performed everywhere for safety

 		String csrfToken = Encode.forHtml(tokenCookie.getValue());
		%>
		<html xmlns="http://www.w3.org/1999/xhtml">
		<head>
		<title>Gorilla Logic CTF 2019 - Scoreboard</title>

		<link href="css/theCss.css" rel="stylesheet" type="text/css" media="screen" />
		<link rel="shortcut icon" href="css/images/flavicon.jpg" type="image/jpeg" />
		</head>
		<body>
		<script type="text/javascript" src="js/jquery.js"></script>
		<script type="text/javascript" src="js/tinysort.js"></script>
		<div id="wrapper">
		<!-- start header -->
		<div id="header">
			<h1>Scoreboard</h1>
			<p>Gorilla Logic CTF 2019 Project</p>
		</div>
		<!-- end header -->
		<!-- start page -->
		<div id="page">
			<!-- start content -->
				<div id="badData"></div>
				<% if(canSeeScoreboard) { %>
					<div id="whereistand-div" style="position: fixed; left:30px; display: none; border-bottom: 3px solid #a878ef;
					background:#d4d4d4; padding: 5px 5px; border-radius: 5px">
							<input type="checkbox" id="whereistand-chk" onChange="whereistandToggle()">Where I stand?
					</div>
					<ul id="leaderboard" class="leaderboard"></ul>
				<% } else { %>
					<p>Scoreboard is not currently available!</p>
				<% } %>
			</div>
			<!-- end content -->
			<!-- start sidebar -->
			<!-- end sidebar -->
		</div>
		</div>
		<!-- end page -->
		<% if(canSeeScoreboard) { %>
			<script>
				var windowIsActive = true;

				window.onfocus = function windowFocus () {
					windowIsActive = true;
				};

				window.onblur = function windowBlur () {
					windowIsActive = false;
				};

				function timeSince(date) {

				    var seconds = Math.floor((new Date() - date) / 1000);

				    var interval = Math.floor(seconds / 31536000);

				    if (interval > 1) {
				        return interval + " years";
				    }
				    interval = Math.floor(seconds / 2592000);
				    if (interval > 1) {
				        return interval + " months";
				    }
				    interval = Math.floor(seconds / 86400);
				    if (interval > 1) {
				        return interval + " days";
				    }
				    interval = Math.floor(seconds / 3600);
				    if (interval > 1) {
				        return interval + " hours";
				    }
				    interval = Math.floor(seconds / 60);
				    if (interval > 1) {
				        return interval + " minutes";
				    }

				    if (Math.floor(seconds) >= 60) {
				    	return "1 minute"
				    }
				    else {
				    	return "< 1 minute";
				    }
				}

				var lastUpdated = new Date();

				//Scoreboard based on http://mightystuff.net/dynamic-leaderboard
				function poll() {
					if(!windowIsActive) { //If Window/Tab is currently not in focus, wait to do the magic
						console.log ( 'Window not active. Waiting' );
						$("#badData").html('<center>Scoreboard last updated ' + timeSince(lastUpdated) + ' ago</center>');
						$("#badData").show("slow");
						t=setTimeout("poll()", 500); // try again really soon
					}
					else { // Window is Active. Do Magic
						console.log ( 'Window Active. Refreshing' );
						var ajaxCall = $.ajax({
							type: "POST",
							url: 'scoreboard', // needs to return a JSON array of items having the following properties: id, score, username
							dataType: 'json',
							data: {
								csrfToken: "<%= csrfToken %>"
							},
							async: false,
							success: function(o) {
								$("#badData").hide("fast");
								for(i=0;i<o.length;i++) {
									if ($('#userbar-'+ o[i].id).length == 0) {
										// this id doesn't exist, so add it to our list.
										var newUser = '<li class="scoreLine"><div id="userbar-'+ o[i].id + '" class="scoreBar" title="' + o[i].userTitle + '" style="width: ' + o[i].scale + '\u0025;">' +
												'<div id="userplace-'+ o[i].id + '" class="place"><h3 style="display:none;" id="user-' + o[i].id + '">' + o[i].order + '</h3>' + getGetOrdinal(o[i].place) + ': </div>'
												+ '<div class="scoreName" >'+ o[i].username
													+ '<div id="goldMedals-' + o[i].id + '" class="medalContainer"><div style="' + o[i].goldDisplay + '"><div class="goldMedalAmountBubble">' + o[i].goldMedalCount + '</div></div></div>'
													+ '<div id="silverMedals-' + o[i].id + '" class="medalContainer"><div style="' + o[i].silverDisplay + '"><div class="silverMedalAmountBubble">' + o[i].silverMedalCount + '</div></div></div>'
													+ '<div id="bronzeMedals-' + o[i].id + '" class="medalContainer"><div style="' + o[i].bronzeDisplay + '"><div class="bronzeMedalAmountBubble">' + o[i].bronzeMedalCount + '</div></div></div>'
												+ '</div><div class="scoreNumber" id="userscore-'+ o[i].id + '">' + o[i].score + '</div></div></li>';
										$("#leaderboard").append(newUser);
									} else {
										// this id does exist
										//update user elements in the list item.
										$('#userbar-'+ o[i].id).prop('title', o[i].userTitle);
										$('#userscore-'+o[i].id).html(o[i].score);
										$('#userplace-'+o[i].id).html('<h3 style="display:none;" id="user-' + o[i].id + '">' + o[i].order + '</h3>' + getGetOrdinal(o[i].place) + ': ');
										$('#goldMedals-' + o[i].id).html('<div style="' + o[i].goldDisplay + '"><div class="goldMedalAmountBubble">' + o[i].goldMedalCount + '</div></div></div>');
										$('#silverMedals-' + o[i].id).html('<div style="' + o[i].silverDisplay + '"><div class="silverMedalAmountBubble">' + o[i].silverMedalCount + '</div></div></div>');
										$('#bronzeMedals-' + o[i].id).html('<div style="' + o[i].bronzeDisplay + '"><div class="bronzeMedalAmountBubble">' + o[i].bronzeMedalCount + '</div></div></div>');
										$('#userbar-'+ o[i].id).animate({
									        width: o[i].scale+"%"
									    }, 1300 );
									}
									// Different color for current user
									$('#userbar-<%= ses.getAttribute("userStamp").toString() %>').css('background-color', 'green');
								}
								sort();

								// Show/hide Where I stand button
								if ($('#userbar-<%= ses.getAttribute("userStamp").toString() %>').length == 0)
									$("#whereistand-div").hide();
								else
									$("#whereistand-div").show();
							}
						});
						var fullResponse = new String(ajaxCall.responseText);
						if (fullResponse.startsWith("ERROR:")) {
							console.log ('Response contained error: ' + fullResponse);
							$("#badData").html('<center>' + fullResponse + '</center>');
							$("#badData").show("slow");
							//Scoreboard will not refresh after this
							console.log("Scoreboard will not refresh following this error");
						} else {
							$("#badData").hide("fast");
							lastUpdated = new Date().getTime();
							// play it again, sam (7 secs)
							t=setTimeout("poll()",7000);
						}
					}
				}

				//Algorithm from http://tinysort.sjeiti.com/
				function sort() {
					var $Ul = $('ul#leaderboard');
					$Ul.css({position:'relative',height:$Ul.height(),display:'block'});
					var iLnH;
					var $Li = $('ul#leaderboard>li');
					$Li.each(function(i,el){
						var iY = $(el).position().top;
						$.data(el,'h',iY);
						if (i===1) iLnH = iY;
					});

					$Li.tsort('h3:eq(0)',{order:'asc'}).each(function(i,el){
						var $El = $(el);
						var iFr = $.data(el,'h');
						var iTo = i*iLnH;
						$El.css({position:'absolute',top:iFr}).animate({top:iTo},500);
					});
				}

				function fixBoard(){
					$("#page").width($(window).width()*0.8);
					var container = $(window);
					var content = $('#page');
					content.css("left", (container.width()-content.width())/2);
				}

				fixBoard();

				$(window).resize(function()
				{
					fixBoard();
				});

				function getGetOrdinal(n) {
				   var s=["th","st","nd","rd"],
					   v=n%100;
				   return n+(s[(v-20)%10]||s[v]||s[0]);
				}
				//Kick off Scoreboard
				poll();

				function whereistandToggle(){
					if ($('#whereistand-chk')[0].checked)
						setInterval(function() {
							whereistandRefresh();
							}, 1000);
					else
						window.scrollTo(0, 0);
				}

				function whereistandRefresh() {
					if ($('#whereistand-chk')[0].checked) {
						place = Number($('#userplace-<%= ses.getAttribute("userStamp").toString() %>')[0].innerText.replace(/\D/g, ''));
						console.log('User is on place ' + place);
						window.scrollTo(0, $('#header').height());

						var s = Number($('#userplace-<%= ses.getAttribute("userStamp").toString() %>').parent().parent().css('top').replace(/\D/g, ''));
						var h = $(window).height()/2;

						if (s > h){
							var d = s - h;
							window.scrollBy(0, d);
						}
					}
				}

			</script>
		<% } %>
		<% if(Analytics.googleAnalyticsOn) { %><%= Analytics.googleAnalyticsScript %><% } %>
		</body>
	</html>
	<%
 	}
	else
	{
		response.sendRedirect("login.jsp");
	}
}
else
{
	response.sendRedirect("login.jsp");
}
%>
