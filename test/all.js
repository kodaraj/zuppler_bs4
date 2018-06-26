exports['test that logs all failures'] = function(assert) {
  assert.equal(2 + 2, 4, 'assert failure is logged')
}

if (module == require.main) require('test').run(exports)
