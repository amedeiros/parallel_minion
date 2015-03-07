require File.join(File.dirname(__FILE__), 'test_helper')

class PoolTest < Minitest::Test
  context ParallelMinion::Pool do
    context '#initialize' do
      should 'raise an exception for missing maximum option' do
        e = assert_raises RuntimeError do
          ParallelMinion::Pool.new
        end

        assert_equal 'Missing required maximum minions', e.message
      end

      should 'assign the maximum number of minions' do
        pool = ParallelMinion::Pool.new(maximum: 1)
        assert_equal 1, pool.maximum
      end

      should 'create a pool that is a queue' do
        pool = ParallelMinion::Pool.new(maximum: 1)
        assert pool.pool.is_a?(Queue)
      end
    end

    context '#count' do
      setup { @pool = ParallelMinion::Pool.new(maximum: 1) }

      should 'return 0 when no minions are in the pool' do
        assert_equal 0, @pool.count
      end

      should 'return 1 when a single minion is in the pool' do
        @pool.worker { 1 + 1 }
        assert_equal 1, @pool.count
      end
    end

    context '#worker' do
      setup { @pool = ParallelMinion::Pool.new(maximum: 2) }

      should 'add a minion to the pool and perform the work' do
        @pool.worker { 1 }
        assert_equal 1, @pool.count
      end

      should 'wait for the lifeguard to pull a minon from the pool when its full' do
        2.times { @pool.worker { 1 } } # Use our maximum minions for this pool
        @pool.worker { 2 } # Go over the maximum minions
        # Count should be 2 not 3. The lifeguard should of pulled one minion form the pool
        assert_equal 2, @pool.count
        # Should be a one for the first minion in the pool
        assert_equal 1, @pool.lifeguard
        # Should be a 2 for our thrid and last minion in the pool
        assert_equal 2, @pool.lifeguard
        # Pool should not be empty
        assert_equal 0, @pool.count
      end
    end

    context '#lifeguard' do
      setup { @pool = ParallelMinion::Pool.new(maximum: 2) }

      should 'return nil when no minions are in the pool' do
        assert_nil @pool.lifeguard
      end

      should 'return the the first result from the first minion in the pool' do
        @pool.worker { 1 }
        @pool.worker { 2 }
        assert_equal 1, @pool.lifeguard
      end
    end

    context '#drain' do
      setup { @pool = ParallelMinion::Pool.new(maximum: 2) }

      should 'return each result for every minion in the pool in an array and empty the pool' do
        @pool.worker { 1 }
        @pool.worker { 2 }
        result = @pool.drain
        assert result.is_a?(Array)
        assert_includes result, 1
        assert_includes result, 2
        assert_equal 0, @pool.count
      end
    end
  end
end
