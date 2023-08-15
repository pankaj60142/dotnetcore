using System;
using System.Collections.Generic;
using System.Linq;

namespace SmartAdmin.Seed.RecExtensions
{
    public static class RecursiveExtension
    {

        public static IEnumerable<T> SelectRecursive<T>(this IEnumerable<T> source, Func<T, IEnumerable<T>> selector)
        {
            foreach (var parent in source)
            {
                yield return parent;

                var children = selector(parent);
                foreach (var child in SelectRecursive(children, selector))
                    yield return child;
            }
        }
    }
}
