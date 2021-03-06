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
	@test.assertEquals (all-1), (@count '[_tamia-yep="yes"]'), 'All visible components initialized'


# Hidden components (Component.isInitializable())
casper.then ->
	@test.assertNotVisible '.js-hidden-component', 'Hidden component is hidden by default'
casper.thenEvaluate ->
	(jQuery '.js-hidden').show().trigger('init.tamia')
casper.then ->
	@test.assertVisible '.js-hidden-component', 'Hidden component is visible now'
	@test.assertEval (->
			(jQuery '.js-hidden-component').hasClass('is-ok')
		), 'Hidden component hidden: has class .is-ok'
	@test.assertEval (->
			(jQuery '.js-hidden-component').hasClass('is-pony')
		), 'Hidden component hidden: has class .is-pony'


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


# Unsupported components (Component.isSupported())
casper.then ->
	@test.assertEval (->
			(jQuery '.js-unsupported-component').hasClass('is-unsupported')
		), 'Unsupported component has class .is-unsupported'
	@test.assertEval (->
			(jQuery '.js-unsupported-component').hasClass('is-no-pony')
		), 'Unsupported component has class .is-no-pony'
	@test.assertEval (->
			!(jQuery '.js-unsupported-component').hasClass('is-ok')
		), 'Unsupported component has no class .is-ok'
	@test.assertEval (->
			!(jQuery '.js-unsupported-component').hasClass('is-pony')
		), 'Unsupported component has no class .is-pony'


# TODO: jQuery shortcuts


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


# Component class
casper.thenEvaluate ->
	window.cmpntElem = document.createElement 'div'
	window.cmpntElem.className = 'pony is-one is-two'
	window.cmpntElem.innerHTML = '<span class="js-elem">42</span>'
	window.cmpnt = new Test window.cmpntElem
casper.then ->
	@test.assertEval (-> !!cmpnt.elem.jquery), 'Component: elem is jQuery object'
	@test.assertEval (-> cmpnt.elemNode.nodeType is 1), 'Component: elemNode is DOM node'
	@test.assertEval (-> !!cmpnt.initializable), 'Component: component initializable'
	@test.assertEval (-> cmpnt.hasState 'ok'), 'Component: has ok state'
	@test.assertEval (-> cmpnt.elem.hasClass 'is-ok'), 'Component: has .is-ok class'
	@test.assertEval (-> cmpnt.hasState('one') and cmpnt.hasState('two')), 'Component: states imported from HTML'
	@test.assertEval (-> cmpnt.elemNode.className is 'pony is-one is-two is-ok'), 'Component: all classes exists in HTML'
	@test.assertEval (-> !!cmpnt.find('elem').jquery), 'Component: elem has found'
casper.thenEvaluate ->
	cmpnt.addState 'three'
	cmpnt.toggleState 'two'
casper.then ->
	@test.assertEval (-> cmpnt.hasState 'three'), 'Component: new state added'
	@test.assertEval (-> not cmpnt.hasState 'two'), 'Component: state toggled (removed)'
	@test.assertEval (-> cmpnt.elemNode.className is 'pony is-one is-ok is-three'), 'Component: new state added to HTML'
casper.thenEvaluate ->
	cmpnt.removeState 'one'
	cmpnt.toggleState 'two'
casper.then ->
	@test.assertEval (-> not cmpnt.hasState 'one'), 'Component: state removed'
	@test.assertEval (-> cmpnt.hasState 'two'), 'Component: state toggled (added)'
	@test.assertEval (-> cmpnt.elemNode.className is 'pony is-two is-ok is-three'), 'Component: state removed from HTML'
casper.thenEvaluate ->
	cmpnt.reset()
	cmpnt.find('elem').trigger 'test1'
casper.then ->
	@test.assertEval (-> cmpnt.handled), 'Component: first event handled'
casper.thenEvaluate ->
	cmpnt.reset()
	cmpnt.find('elem').trigger 'test2'
casper.then ->
	@test.assertEval (-> cmpnt.handled), 'Component: second event handled'
casper.thenEvaluate ->
	cmpnt.detachFirstHandler()
	cmpnt.reset()
	cmpnt.find('elem').trigger 'test1'
casper.then ->
	@test.assertEval (-> not cmpnt.handled), 'Component: first event not handled after off() call'
casper.thenEvaluate ->
	cmpnt.reset()
	cmpnt.find('elem').trigger 'test2'
casper.then ->
	@test.assertEval (-> cmpnt.handled), 'Component: second event still handled'
casper.thenEvaluate ->
	cmpnt.detachSecondHandler()
	cmpnt.reset()
	cmpnt.find('elem').trigger 'test2'
casper.then ->
	@test.assertEval (-> not cmpnt.handled), 'Component: second event not handled after off() call'


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
