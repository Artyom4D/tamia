casper = require('casper').create
	verbose: true
	# logLevel: 'debug'

casper.on 'remote.message', (message) ->
    console.log 'BROWSER:', message

casper.count = (s) ->
	@evaluate ((s) ->
		(document.querySelectorAll s).length
	), s


casper.start 'specs/specs.html'

# Ensure page was created
casper.then ->
	@test.assertTitle 'Tâmia', 'Specs file loaded'


###########
# JS core #
###########

# All components initialized
casper.then ->
	all = @count '[data-component]'
	@test.assert all > 0, 'There are some components'
	@test.assertEquals all, (@count '[_tamia-yep="yes"]'), 'All components initialized'


# Dynamic initialization
casper.thenEvaluate ->
	container = (jQuery '.js-container')
	container.html container.html().replace /_tamia-yep="yes"/g, '',
casper.then ->
	@test.assertExists '.js-container [data-component]', 'There are some new components'
	@test.assertNotExists '.js-container [_tamia-yep]', 'All new components not initialized'
casper.thenEvaluate ->
	(jQuery '.js-container').trigger 'init.tamia'
casper.then ->
	@test.assertEquals (@count '[data-component]'), (@count '[_tamia-yep="yes"]'), 'All new components initialized'


# Appear/disappear
casper.thenEvaluate ->
	@test.assertNotVisible '.js-dialog', 'Dialog is hidden by default'

casper.thenClick '.js-appear', ->
	@test.assertVisible '.js-dialog', 'Dialog is visible after click on Appear link'
	@test.assertExists '.js-dialog.is-transit', 'Dialog has .is-transit class just after click'

casper.wait 750, ->
	@test.assertVisible '.js-dialog', 'Dialog is still visible after transition ends'
	@test.assertEval (->
		!(jQuery '.js-dialog').hasClass('is-transit')
	), '.is-transit class has been removed after transition but before fallback timeout'

casper.thenClick '.js-disappear', ->
	@test.assertVisible '.js-dialog', 'Dialog is visible just after click on Disappear link'
	@test.assertExists '.js-dialog.is-transit', 'Dialog has .is-transit class just after click'

casper.wait 750, ->
	@test.assertNotVisible '.js-dialog', 'Dialog is not visible after transition ends'
	@test.assertEval (->
		!(jQuery '.js-dialog').hasClass('is-transit')
	), '.is-transit class has been removed after transition but before fallback timeout'


# Controls
casper.thenClick '.js-control-link', ->
	@test.assertSelectorHasText '.js-control-target',  '1two', 'Event was fired, arguments passed properly'


##########
# Blocks #
##########

# Password
casper.then ->
	@test.assertEval (->
		(jQuery '.js-password').hasClass('is-ok')
	), 'Password: initialized'
	@test.assertEvalEquals (->
		(jQuery '.js-password .password__field').attr('type')
	), 'password', 'Password: default input type is "password"'
casper.thenEvaluate ->
	(jQuery '.js-password .password__field').focus()
	(jQuery '.js-password .password__toggle').mousedown()
casper.then ->
	@test.assertEval (->
		(jQuery '.js-password').hasClass('is-unlocked')
	), 'Password: container has class "is-unlocked"'
	@test.assertEvalEquals (->
		(jQuery '.js-password .password__field').attr('type')
	), 'text', 'Password: input type is "text" after toggle'
	@test.assertEval (->
		document.activeElement == (jQuery '.js-password .password__field')[0]
	), 'Password: input has focus'


# Flippable
casper.then ->
	@test.assertEval (->
		!(jQuery '.js-flip').hasClass('is-flipped')
	), 'Flippable: not flipped by default'
casper.thenEvaluate ->
	(jQuery '.js-flip').click()
casper.then ->
	@test.assertEval (->
		(jQuery '.js-flip').hasClass('is-flipped')
	), 'Flippable: flipped after click'


# Select
casper.thenEvaluate ->
	(jQuery '.js-select').val('dog').change()
casper.then ->
	@test.assertSelectorHasText '.js-select-component', 'Dog', 'Select: text in text box changed'
casper.thenEvaluate ->
	(jQuery '.js-select').focus()
casper.then ->
	@test.assertEval (->
		(jQuery '.js-select-component').hasClass('is-focused')
	), 'Select: focused state set'
casper.thenEvaluate ->
	(jQuery '.js-select').blur()
casper.then ->
	@test.assertEval (->
		!(jQuery '.js-select-component').hasClass('is-focused')
	), 'Select: focused state removed'


casper.run ->
	@test.renderResults true
